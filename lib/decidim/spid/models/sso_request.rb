module Decidim
  module Spid

    class SsoRequest < ::OneLogin::RubySaml::Authrequest

      attr_accessor :settings, :options

      def initialize spid_params, options
        @settings = Settings::Sso.new(options.merge(idp: spid_params.dig(:sso, :idp)))
        @request = OneLogin::RubySaml::Authrequest.new
      end

      def to_saml
        if @settings.valid?
          hash_settings = @settings.settings
          saml_settings = OneLogin::RubySaml::Settings.new(hash_settings)
          @request.create(saml_settings, :RelayState => Base64.strict_encode64(hash_settings.delete(:relay_state)))
        else
          raise OneLogin::RubySaml::ValidationError, @settings.errors.try(:first)
        end
      end

    end

  end
end