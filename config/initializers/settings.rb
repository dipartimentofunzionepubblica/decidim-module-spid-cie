require "xml_security"
require "onelogin/ruby-saml/attribute_service"
require "onelogin/ruby-saml/utils"
require "onelogin/ruby-saml/validation_error"

# Only supports SAML 2.0
module OneLogin
  module RubySaml

    # SAML2 Toolkit Settings
    #
    class Settings

      attr_reader :logout_services, :consumer_services, :default_service_index, :current_consumer_index, :current_logout_index

      def initialize(overrides = {}, keep_security_attributes = false)
        if keep_security_attributes
          security_attributes = overrides.delete(:security) || {}
          config = DEFAULTS.merge(overrides)
          config[:security] = DEFAULTS[:security].merge(security_attributes)
        else
          config = DEFAULTS.merge(overrides)
        end

        config.each do |k, v|
          acc = "#{k.to_s}=".to_sym
          if respond_to? acc
            value = v.is_a?(Hash) ? v.dup : v
            send(acc, value)
          end
        end
        @attribute_consuming_service = config[:attribute_consuming_service].present? ? config[:attribute_consuming_service] : AttributeService.new
        @consumer_services = config[:consumer_services]
        @logout_services = config[:logout_services]
        @default_service_index = config[:default_service_index]
        @current_consumer_index = config[:current_consumer_index]
        @current_logout_index = config[:current_logout_index]
      end
    end
  end
end