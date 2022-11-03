# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# frozen_string_literal: true

# Gestisce il login omniauth SPID

module Decidim
  module Spid
    class OmniauthCallbacksController < ::Decidim::Devise::OmniauthRegistrationsController
      helper Decidim::Spid::Engine.routes.url_helpers
      helper_method :omniauth_registrations_path

      skip_before_action :verify_authenticity_token, only: [:spid, :failure]
      skip_after_action :verify_same_origin_request, only: [:spid, :failure]

      def spid
        session["decidim-spid.signed_in"] = true
        session["decidim-spid.tenant"] = tenant.name

        authenticator.validate!

        if user_signed_in?
          authenticator.identify_user!(current_user)

          # Aggiunge l'autorizzazione per l'utente
          return fail_authorize unless authorize_user(current_user)

          # Aggiorna le informazioni dell'utente
          authenticator.update_user!(current_user)

          Decidim::Spid::SpidJob.perform_later(current_user)
          flash[:notice] = t("authorizations.create.success", scope: "decidim.spid.verification")
          return redirect_to(stored_location_for(resource || :user) || decidim.root_path)
        end

        # Normale richiesta di autorizzazione, procede con la logica di Decidim
        send(:create)

      rescue Decidim::Spid::Authentication::ValidationError => e
        fail_authorize(e.validation_key)
      rescue Decidim::Spid::Authentication::IdentityBoundToOtherUserError
        fail_authorize(:identity_bound_to_other_user)
      end

      def create
        form_params = user_params_from_oauth_hash || params.require(:user).permit!
        form_params.merge!(params.require(:user).permit!) if params.dig(:user).present?
        origin = Base64.strict_decode64(session[:"#{session_prefix}sso_params"]["relay_state"]) rescue ''

        invitation_token = invitation_token(origin)
        verified_e = verified_email

        # nel caso la form di integrazione dati viene presentata
        invited_user = nil
        if invitation_token.present?
          invited_user = resource_class.find_by_invitation_token(invitation_token, true)
          invited_user.nickname = nil # Forzo nickname a nil per invalidare il valore normalizzato di Decidim di default
          @form = form(OmniauthSpidRegistrationForm).from_params(invited_user.attributes.merge(form_params))
          @form.invitation_token = invitation_token
          @form.email ||= invited_user.email
          verified_e = invited_user.email
        else
          @form = form(OmniauthSpidRegistrationForm).from_params(form_params)
          @form.email ||= verified_e
          verified_e ||= form_params.dig(:email)
        end

        # Controllo che non esisti un'altro account con la stessa email utilizzata con SPID
        # in quanto a fine processo all'utente viene aggiornata l'email e il tutto protrebbe essere invalido
        if invited_user.present? && form_params.dig(:raw_data, :info, :email).present? && invited_user.email != form_params.dig(:raw_data, :info, :email) &&
          current_organization.users.where(email: form_params.dig(:raw_data, :info, :email)).where.not(id: invited_user.id).present?
          set_flash_message :alert, :failure, kind: "SPID", reason: t("decidim.devise.omniauth_registrations.create.email_already_exists")
          return redirect_to after_omniauth_failure_path_for(resource_name)
        end

        existing_identity = Identity.find_by(
          user: current_organization.users,
          provider: @form.provider,
          uid: @form.uid
        )

        CreateOmniauthSpidRegistration.call(@form, verified_e) do
          on(:ok) do |user|
            # Se l'identità SPID è già utilizzata da un altro account
            if invited_user.present? && invited_user.email != user.email
              set_flash_message :alert, :failure, kind: "SPID", reason: t("decidim.devise.omniauth_registrations.create.email_already_exists")
              return redirect_to after_omniauth_failure_path_for(resource_name)
            end

            # match l'utente dell'invitation token passato come relay_state in SPID Strategy,
            # associo l'identity SPID all'utente creato nell'invitation e aggiorno l'email dell'utente con quella dello SPID.
            if invitation_token.present? && invited_user.present? && invited_user.email == user.email
              # per accettare resource_class.accept_invitation!(devise_parameter_sanitizer.sanitize(:accept_invitation).merge(invitation_token: invitation_token))
              user = resource_class.find_by_invitation_token(invitation_token, true)
              # nuovo utente senza password, fallirebbero le validazioni
              token = ::Devise.friendly_token
              user.password = token
              user.password_confirmation = token
              user.save(validate: false)
              user.accept_invitation!
            end

            if user.active_for_authentication?
              if existing_identity
                Decidim::ActionLogger.log(:login, user, existing_identity, {})
              else
                i = user.identities.find_by(uid: session["#{session_prefix}uid"]) rescue nil
                Decidim::ActionLogger.log(:registration, user, i, {})
              end
              sign_in_and_redirect user, verified_email: verified_e, event: :authentication
              set_flash_message :notice, :success, kind: "SPID"
            else
              expire_data_after_sign_in!
              user.resend_confirmation_instructions unless user.confirmed?
              redirect_to decidim.root_path
              flash[:notice] = t("devise.registrations.signed_up_but_unconfirmed")
            end
          end

          on(:invalid) do
            set_flash_message :notice, :success, kind: "SPID"
            render :new
          end

          on(:error) do |user|
            set_flash_message :alert, :failure, kind: "SPID", reason: user.errors.full_messages.try(:first)

            render :new
          end
        end
      end

      def failure
        strategy = failed_strategy
        saml_response = strategy.response_object if strategy
        return super unless saml_response

        validations = [ :success_status, :session_expiration ]
        validations.each do |key|
          next if saml_response.send("validate_#{key}")

          flash[:alert] = failure_message || t(".#{key}")
          return redirect_to after_omniauth_failure_path_for(resource_name)
        end

        set_flash_message! :alert, :failure, kind: "SPID", reason: failure_message
        redirect_to after_omniauth_failure_path_for(resource_name)
      end

      def sign_in_and_redirect(resource_or_scope, *args)
        if resource_or_scope.is_a?(::Decidim::User)
          return fail_authorize unless authorize_user(resource_or_scope)

          authenticator.update_user!(resource_or_scope)
        end

        super
      end

      def first_login_and_not_authorized?(_user)
        false
      end

      protected

      def failure_message
        error = request.respond_to?(:get_header) ? request.get_header("omniauth.error") : request.env["omniauth.error"]
        I18n.t(error) rescue nil
      end

      private

      def authorize_user(user)
        authenticator.authorize_user!(user)
      rescue Decidim::Spid::Authentication::AuthorizationBoundToOtherUserError
        nil
      end

      def fail_authorize(failure_message_key = :already_authorized)
        flash[:alert] = t("failure.#{failure_message_key}", scope: "decidim.spid.omniauth_callbacks")
        redirect_to stored_location_for(resource || :user) || decidim.root_path
      end

      def omniauth_registrations_path(resource)
        decidim_spid.public_send("user_#{current_organization.enabled_omniauth_providers.dig(:spid, :tenant_name)}_omniauth_create_url")
      end

      def user_params_from_oauth_hash
        authenticator.user_params_from_oauth_hash
      end

      def authenticator
        @authenticator ||= tenant.authenticator_for(
          current_organization,
          oauth_hash
        )
      end

      def tenant
        @tenant ||= begin
                      name = session["tenant-spid-name"]
                      raise "Invalid SPID tenant" unless name

                      tenant = Decidim::Spid.tenants.find { |t| t.name == name }
                      raise "Unkown SPID tenant: #{name}" unless tenant

                      tenant
                    end
      end

      def session_prefix
        tenant.name + '_spid_'
      end

      def invitation_token(url)
        begin
          CGI.parse(URI.parse(url).query).dig('invitation_token').first
        rescue
          nil
        end
      end

      def verified_email
        authenticator.verified_email
      end

      def oauth_hash
        raw_hash = request.env["omniauth.auth"] || JSON.parse(params.dig(:user, :raw_data))
        return {} unless raw_hash

        raw_hash.deep_symbolize_keys
      end
    end
  end
end
