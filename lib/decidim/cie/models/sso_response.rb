module Decidim
  module Cie
    class SsoResponse

      attr_accessor :response

      def initialize saml_response, sso_params, options
        response = OneLogin::RubySaml::Response.new(saml_response)
        settings = Settings::Sso.new(options.merge(idp: sso_params.dig("sso", "idp")))
        saml_settings = OneLogin::RubySaml::Settings.new(settings.settings)
        response.settings = saml_settings
        @response = response
      end

      def valid?
        @response.is_valid?
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

    end

  end
end