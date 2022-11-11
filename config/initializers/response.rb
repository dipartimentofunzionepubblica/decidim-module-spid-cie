# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Necessario override per supportare validazaionoi per multipli AttributeConsumingService, SingleLogoutService
module OneLogin
  module RubySaml

    class Response < SamlMessage


      def validate_destination
        return true if destination.nil?
        return true if options[:skip_destination]

        if destination.empty?
          error_msg = "The response has an empty Destination value"
          return append_error(error_msg)
        end

        if settings.consumer_services.present?
          url = settings.consumer_services[settings.current_consumer_index]['Location'] rescue ''
          unless OneLogin::RubySaml::Utils.uri_match?(destination, url)
            error_msg = "The response was received at #{destination} instead of #{url}"
            return append_error(error_msg)
          else
            return true
          end
        else
          return true if settings.assertion_consumer_service_url.nil? || settings.assertion_consumer_service_url.empty?
        end

        unless OneLogin::RubySaml::Utils.uri_match?(destination, settings.assertion_consumer_service_url)
          error_msg = "The response was received at #{destination} instead of #{settings.assertion_consumer_service_url}"
          return append_error(error_msg)
        end

        true
      end

    end
  end
end