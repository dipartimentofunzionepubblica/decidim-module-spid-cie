# frozen_string_literal: true

require 'decidim/spid/token_verifier'

module Decidim
  module Cie
    class Tenant
      include ActiveSupport::Configurable

      # Il nome che identificata il singolo Tenant. Default: cie
      config_accessor :name, instance_writer: false do
        "cie"
      end

      config_accessor :sp_entity_id, instance_reader: false do
        #todo: da gestire
      end

      # Certificato in string
      config_accessor :certificate, instance_reader: false

      # Chiave privata in string
      config_accessor :private_key, instance_reader: false

      # Percorso relativo alla root dell'app del certificato
      config_accessor :certificate_path do
        '.keys/certificate.pem'
      end

      # Percorso relativo alla root dell'app della chiave privata
      config_accessor :private_key_path do
        '.keys/private_key.pem'
      end

      # Percorso relativo alla root dell'app del nuovo certificato
      config_accessor :new_certificate_path do
        nil
      end

      # Defines how the session gets cleared when the OmniAuth strategy logs the
      # user out. This has been customized to preserve the flash messages and the
      # stored redirect location in the session after the session is destroyed.
      config_accessor :idp_slo_session_destroy do
        proc do |_env, session|
          flash = session["flash"]
          return_to = session["user_return_to"]
          result = session.clear
          session["flash"] = flash if flash
          session["user_return_to"] = return_to if return_to
          result
        end
      end

      # These are extra attributes that can be stored for the authorization
      # metadata.
      config_accessor :metadata_attributes do
        {}
      end

      # Fields to exclude from export due GDPR policy. Array of key from metadata_attributes
      config_accessor :export_exclude_attributes do
        []
      end

      # Extra metadata to be included in the service provider metadata. Define as
      # follows:
      #
      # Decidim::Cie.configure do |config|
      #   # ...
      #   config.sp_metadata = [
      #     {
      #       name: "Organization",
      #       children: [
      #         {
      #           name: "OrganizationName",
      #           attributes: { "xml:lang" => "en-US" },
      #           content: "Acme"
      #         }
      #       ]
      #     }
      #   ]
      # end
      config_accessor :organization do
        {}
      end

      config_accessor :contact_people_administrative do
        {}
      end

      config_accessor :contact_people_technical do
        {}
      end

      config_accessor :fields do
        {}
      end

      # Extra configuration for the omniauth strategy
      config_accessor :extra do
        {}
      end

      # Allows customizing the authorization workflow e.g. for adding custom
      # workflow options or configuring an action authorizer for the
      # particular needs.
      config_accessor :workflow_configurator do
        lambda do |workflow|
          # By default, expiration is set to 0 minutes which means it will
          # never expire.
          workflow.expires_in = 0.minutes
        end
      end

      # Allows customizing parts of the authentication flow such as validating
      # the authorization data before allowing the user to be authenticated.
      config_accessor :authenticator_class do
        Decidim::Cie::Authentication::Authenticator
      end

      # Allows customizing how the authorization metadata gets collected from
      # the SAML attributes passed from the authorization endpoint.
      config_accessor :metadata_collector_class do
        Decidim::Cie::Verification::MetadataCollector
      end

      # Il livello CIE richiesto dal tenant
      config_accessor :cie_level do
        2
      end

      config_accessor :relay_state do
        '/'
      end

      config_accessor :sha do
        256
      end

      config_accessor :uid_attribute do
        :fiscalNumber
      end

      def initialize
        yield self
      end

      def name=(name)
        raise(InvalidTenantName, "Il nome del tenant CIE può contenere solo lettere o underscore.") unless name.match?(/^[a-z_]+$/)
        config.name = name
      end

      def authenticator_for(organization, oauth_hash)
        authenticator_class.new(self, organization, oauth_hash)
      end

      def metadata_collector_for(saml_attributes)
        metadata_collector_class.new(self, saml_attributes)
      end

      def sp_entity_id
        return config.sp_entity_id if config.sp_entity_id

        "#{application_host}/users/auth/#{config.name}/metadata"
      end

      def certificate
        return File.read(certificate_path) if certificate_path && File.exists?(Rails.root.join(certificate_path))

        config.certificate_path
      end

      def private_key
        return File.read(private_key_path) if private_key_path && File.exists?(Rails.root.join(private_key_path))

        config.private_key_path
      end

      def new_certificate
        return File.read(new_certificate_path) if new_certificate_path && File.exists?(Rails.root.join(new_certificate_path))

        config.new_certificate_path
      end

      def omniauth_settings
        {
          name: name,
          strategy_class: OmniAuth::Strategies::CieSaml,
          sp_entity_id: sp_entity_id,
          sp_name_qualifier: sp_entity_id,
          idp_slo_session_destroy: idp_slo_session_destroy,
          sp_metadata: {},
          certificate: certificate,
          private_key: private_key,
          new_certificate: new_certificate,
          assertion_consumer_service_url: "#{sp_entity_id}users/auth/#{config.name}/callback",
          single_logout_service_url: "#{sp_entity_id}users/auth/#{config.name}/slo",
          config: config
        }.merge(extra)
      end

      def setup!
        setup_routes!

        # Configure the SAML OmniAuth strategy for Devise
        ::Devise.setup do |config|
          config.omniauth(name.to_sym, omniauth_settings)
        end

        # Customized version of Devise's OmniAuth failure app in order to handle
        # the failures properly. Without this, the failure requests would end
        # up in an ActionController::InvalidAuthenticityToken exception.
        devise_failure_app = OmniAuth.config.on_failure
        OmniAuth.config.request_validation_phase = Decidim::Spid::TokenVerifier.new
        OmniAuth.config.on_failure = proc do |env|
          if env["PATH_INFO"] && env["PATH_INFO"].match?(%r{^/users/auth/#{config.name}($|/.+)})
            env["devise.mapping"] = ::Devise.mappings[:user]
            Decidim::Cie::OmniauthCallbacksController.action(
              :failure
            ).call(env)
          else
            # Call the default for others.
            devise_failure_app.call(env)
          end
        end
      end

      def setup_routes!
        # This assignment makes the config variable accessible in the block
        # below.
        config = self.config
        Decidim::Cie::Engine.routes do
          devise_scope :user do
            # Manually map the SAML omniauth routes for Devise because the default
            # routes are mounted by core Decidim. This is because we want to map
            # these routes to the local callbacks controller instead of the
            # Decidim core.
            # See: https://git.io/fjDz1
            match(
              "/users/auth/#{config.name}",
              to: "omniauth_callbacks#passthru",
              as: "user_#{config.name}_omniauth_authorize",
              via: [:get, :post]
            )

            match(
              "/users/auth/#{config.name}/callback",
              to: "omniauth_callbacks#cie",
              as: "user_#{config.name}_omniauth_callback",
              via: [:get, :post]
            )

            match(
              "/users/auth/#{config.name}/create",
              to: "omniauth_callbacks#create",
              as: "user_#{config.name}_omniauth_create",
              via: [:post, :put, :patch]
            )

            # Add the SLO and SPSLO paths to be able to pass these requests to
            # OmniAuth.
            match(
              "/users/auth/#{config.name}/slo",
              to: "sessions#slo",
              as: "user_#{config.name}_omniauth_slo",
              via: [:get, :post]
            )

            match(
              "/users/auth/#{config.name}/spslo",
              to: "sessions#spslo",
              as: "user_#{config.name}_omniauth_spslo",
              via: [:get, :post]
            )
          end
        end
      end

      # Used to determine the default service provider entity ID in case not
      # specifically set by the `sp_entity_id` configuration option.
      def application_host
        url_options = application_url_options

        # Note that at least Azure AD requires all callback URLs to be HTTPS, so
        # we'll default to that.
        host = url_options[:host]
        port = url_options[:port]
        protocol = url_options[:protocol]
        protocol = [80, 3000].include?(port.to_i) ? "http" : "https" if protocol.blank?
        if host.blank?
          # Default to local development environment.
          host = "localhost"
          port ||= 3000
        end

        return "#{protocol}://#{host}:#{port}" if port && [80, 443].exclude?(port.to_i)

        "#{protocol}://#{host}"
      end

      def application_url_options
        conf = Rails.application.config
        url_options = conf.action_controller.default_url_options
        url_options = conf.action_mailer.default_url_options if !url_options || !url_options[:host]
        url_options || {}
      end
    end
  end
end
