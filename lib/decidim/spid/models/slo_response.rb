module Decidim
  module Spid
    class SloResponse

      attr_accessor :response

      def initialize saml_response, slo_params, options
        spid_settings = Settings::Slo.new(options.merge(idp: slo_params.dig("sso", "idp")))
        settings = OneLogin::RubySaml::Settings.new(spid_settings.settings)
        @response = OneLogin::RubySaml::Logoutresponse.new(saml_response,
                                                           settings,
                                                           matches_request_id: slo_params.dig(:slo_id))
      end

      def valid?
        @response.validate
      end

      def inspect
        @response.inspect
      end

      def errors
        @response.errors
      end

    end

  end
end