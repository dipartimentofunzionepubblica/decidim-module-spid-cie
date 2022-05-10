# frozen_string_literal: true

module Decidim
  module Spid
    class OmniauthCallbacksController < ::Decidim::Devise::OmniauthRegistrationsController
      # Make the view helpers available needed in the views
      helper Decidim::Spid::Engine.routes.url_helpers
      helper_method :omniauth_registrations_path

      skip_before_action :verify_authenticity_token, only: [:spid, :failure]
      skip_after_action :verify_same_origin_request, only: [:spid, :failure]

      # This is called always after the user returns from the authentication
      # flow from the Active Directory identity provider.
      def spid
        session["decidim-spid.signed_in"] = true
        session["decidim-spid.tenant"] = tenant.name

        authenticator.validate!

        if user_signed_in?
          # The user is most likely returning from an authorization request
          # because they are already signed in. In this case, add the
          # authorization and redirect the user back to the authorizations view.

          # Make sure the user has an identity created in order to aid future
          # Active Directory sign ins. In case this fails, it will raise a
          # Decidim::Msad::Authentication::IdentityBoundToOtherUserError
          # which is handled below.
          authenticator.identify_user!(current_user)

          # Add the authorization for the user
          return fail_authorize unless authorize_user(current_user)

          # Make sure the user details are up to date
          authenticator.update_user!(current_user)

          # Show the success message and redirect back to the authorizations
          flash[:notice] = t(
            "authorizations.create.success",
            scope: "decidim.spid.verification"
          )
          return redirect_to(
            stored_location_for(resource || :user) ||
              decidim.root_path
          )
        end

        # Normal authentication request, proceed with Decidim's internal logic.
        send(:create)

      rescue Decidim::Spid::Authentication::ValidationError => e
        fail_authorize(e.validation_key)
      rescue Decidim::Spid::Authentication::IdentityBoundToOtherUserError
        fail_authorize(:identity_bound_to_other_user)
      end

      def create
        form_params = user_params_from_oauth_hash || params.require(:user).permit!
        origin = Base64.strict_decode64(session[:"#{Decidim::Spid::Utils.session_prefix}sso_params"]["relay_state"]) rescue ''

        invitation_token = invitation_token(origin)
        verified_e = verified_email

        # nel caso la form di integrazione dati viene presentata
        invited_user = nil
        if invitation_token.present?
          invited_user = resource_class.find_by_invitation_token(invitation_token, true)
          @form = form(OmniauthRegistrationForm).from_params(invited_user.attributes.merge(form_params))
          @form.email ||= invited_user.email
          verified_e = invited_user.email
        else
          @form = form(OmniauthRegistrationForm).from_params(form_params)
          @form.email ||= verified_e
          verified_e ||= form_params.dig(:email)
        end

        # Controllo che non esisti un'altro account con la stessa email utilizzata con SPID
        # in quanto a fine processo all'utente viene aggiornata l'email e il tutto protrebbe essere invalido
        if invited_user.present? && form_params.dig(:raw_data, :info, :email).present? && invited_user.email != form_params.dig(:raw_data, :info, :email) &&
          current_organization.users.where(email: form_params.dig(:raw_data, :info, :email)).where.not(id: invited_user.id).present?
          set_flash_message :alert, :failure, kind: @form.provider.capitalize, reason: t("decidim.devise.omniauth_registrations.create.email_already_exists")
          return redirect_to after_omniauth_failure_path_for(resource_name)
        end

        existing_identity = Identity.find_by(
          user: current_organization.users,
          provider: @form.provider,
          uid: @form.uid
        )

        CreateOmniauthRegistration.call(@form, verified_e) do
          on(:ok) do |user|
            # Se l'identità SPID è già utilizzata da un'altro account
            if invited_user.present? && invited_user.email != user.email
              set_flash_message :alert, :failure, kind: @form.provider.capitalize, reason: t("decidim.devise.omniauth_registrations.create.email_already_exists")
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
                i = user.identities.find_by(uid: session["#{Decidim::Spid::Utils.session_prefix}uid"]) rescue nil
                Decidim::ActionLogger.log(:registration, user, i, {})
              end
              sign_in_and_redirect user, verified_email: verified_e, event: :authentication
              set_flash_message :notice, :success, kind: @form.provider.capitalize
            else
              expire_data_after_sign_in!
              user.resend_confirmation_instructions unless user.confirmed?
              redirect_to decidim.root_path
              flash[:notice] = t("devise.registrations.signed_up_but_unconfirmed")
            end
          end

          on(:invalid) do
            set_flash_message :notice, :success, kind: @form.provider.capitalize
            render :new
          end

          on(:error) do |user|
            if user.errors[:email]
              set_flash_message :alert, :failure, kind: @form.provider.capitalize, reason: t("decidim.devise.omniauth_registrations.create.email_already_exists")
            end

            render :new
          end
        end
      end

      def failure
        strategy = failed_strategy
        saml_response = strategy.response_object if strategy
        return super unless saml_response

        validations = [
          # The success status validation fails in case the response status
          # code is something else than "Success". This is most likely because
          # of one the reasons explained above. In general there are few
          # possible explanations for this:
          # 1. The user cancelled the request and returned to the service.
          # 2. The underlying identity service the IdP redirects to rejected
          #    the request for one reason or another. E.g. the user cancelled
          #    the request at the identity service.
          # 3. There is some technical problem with the identity provider
          #    service or the XML request sent to there is malformed.
          :success_status,
          # Checks if the local session should be expired, i.e. if the user
          # took too long time to go through the authorization endpoint.
          :session_expiration,
          # The NotBefore and NotOnOrAfter conditions failed, i.e. whether the
          # request is handled within the allowed timeframe by the IdP.
          :conditions
        ]
        validations.each do |key|
          next if saml_response.send("validate_#{key}")

          flash[:alert] = t(".#{key}")
          return redirect_to after_omniauth_failure_path_for(resource_name)
        end

        super
      end

      # This is overridden method from the Devise controller helpers
      # This is called when the user is successfully authenticated which means
      # that we also need to add the authorization for the user automatically
      # because a succesful Active Directory authentication means the user has
      # been successfully authorized as well.
      def sign_in_and_redirect(resource_or_scope, *args)
        # Add authorization for the user
        if resource_or_scope.is_a?(::Decidim::User)
          return fail_authorize unless authorize_user(resource_or_scope)

          # Make sure the user details are up to date
          authenticator.update_user!(resource_or_scope)
        end

        super
      end

      # Disable authorization redirect for the first login
      def first_login_and_not_authorized?(_user)
        false
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

      # Needs to be specifically defined because the core engine routes are not
      # all properly loaded for the view and this helper method is needed for
      # defining the omniauth registration form's submit path.
      def omniauth_registrations_path(resource)
        decidim_spid.public_send("user_#{current_organization.enabled_omniauth_providers.dig(:spid, :tenant_name)}_omniauth_create_url")
      end

      # Private: Create form params from omniauth hash
      # Since we are using trusted omniauth data we are generating a valid signature.
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
                      matches = request.path.match(%r{^/users/auth/([^/]+)/.+})
                      raise "Invalid SPID tenant" unless matches

                      name = matches[1]
                      tenant = Decidim::Spid.tenants.find { |t| t.name == name }
                      raise "Unkown SPID tenant: #{name}" unless tenant

                      tenant
                    end
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
    end
  end
end
