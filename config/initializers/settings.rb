# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

require "xml_security"
require "onelogin/ruby-saml/attribute_service"
require "onelogin/ruby-saml/utils"
require "onelogin/ruby-saml/validation_error"

# Only supports SAML 2.0
module OneLogin
  module RubySaml

    class Settings

      attr_reader :logout_services, :consumer_services, :default_service_index, :current_consumer_index, :current_attribute_index, :current_logout_index, :attribute_service_names

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
        @attribute_service_names = config[:attribute_service_names]
        @consumer_services = config[:consumer_services]
        @logout_services = config[:logout_services]
        @default_service_index = config[:default_service_index]
        @current_consumer_index = config[:current_consumer_index]
        @current_logout_index = config[:current_logout_index]
        @current_attribute_index = config[:current_attribute_index]
      end
    end
  end
end