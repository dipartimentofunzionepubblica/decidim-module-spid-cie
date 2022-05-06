require 'onelogin/ruby-saml/validation_error'
module Decidim
  module Spid
    class SloRequest < ::OneLogin::RubySaml::Logoutrequest

      attr_accessor :settings, :options

      def initialize(slo_params, options)
        @settings = Settings::Slo.new(options.merge(idp: slo_params.dig(:sso, :idp)))
        @request = OneLogin::RubySaml::Logoutrequest.new
      end

      def uuid
        @request.uuid
      end

      def to_saml
        if @settings.valid?
          hash_settings = @settings.settings
          saml_settings = OneLogin::RubySaml::Settings.new(hash_settings)
          @request.create(saml_settings, :RelayState => hash_settings.delete(:relay_state))
        else
          raise OneLogin::RubySaml::ValidationError, @settings.errors.try(:first)
        end
      end

    end
  end
end