# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Necessario override per aggiunge log
require "onelogin/ruby-saml/validation_error"

module OneLogin
  module RubySaml
    module ErrorHandling
      attr_accessor :errors

      # Append the cause to the errors array, and based on the value of soft, return false or raise
      # an exception. soft_override is provided as a means of overriding the object's notion of
      # soft for just this invocation.
      def append_error(error_msg, soft_override = nil)
        @errors << error_msg
        Rails.logger.info("decidim-module-spid-cie || #{error_msg}")

        unless soft_override.nil? ? soft : soft_override
          raise ValidationError.new(error_msg)
        end

        false
      end

      # Reset the errors array
      def reset_errors!
        @errors = []
      end
    end
  end
end
