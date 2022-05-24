require 'decidim/spid/validations'

module Decidim
  module Cie
    class SsoResponse

      include Decidim::Spid::Validations

      attr_accessor :response, :sso_params, :authn_context

      def initialize saml_response, sso_params, options
        options["matches_request_id"] = sso_params.dig("uuid")
        response = OneLogin::RubySaml::Response.new(saml_response, options)
        settings = Settings::Sso.new(options.merge(idp: sso_params.dig("sso", "idp")))
        @authn_context = settings.settings[:authn_context].sub(/[1-3]$/, '')
        saml_settings = OneLogin::RubySaml::Settings.new(settings.settings)
        response.settings = saml_settings
        @sso_params = sso_params
        @response = response
      end

      def valid?
        @response.is_valid? && validate!
      end

      def inspect
        @response.inspect
      end

      def session_index
        @response.sessionindex
      end

      def session_expire_at
        @response.session_expires_at
      end

      def errors
        @response.errors
      end

      def key_level
        "cie_level"
      end

    end

  end
end