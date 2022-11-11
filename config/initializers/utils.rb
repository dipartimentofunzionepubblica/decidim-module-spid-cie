# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

module OneLogin
  module RubySaml

    class Utils

      def self.uri_match?(destination_url, settings_url)
        dest_uri = URI.parse(destination_url.try(:strip))
        acs_uri = URI.parse(settings_url.try(:strip))

        if dest_uri.scheme.nil? || acs_uri.scheme.nil? || dest_uri.host.nil? || acs_uri.host.nil?
          raise URI::InvalidURIError
        else
          dest_uri.scheme.downcase == acs_uri.scheme.downcase &&
            dest_uri.host.downcase == acs_uri.host.downcase &&
            dest_uri.path == acs_uri.path &&
            dest_uri.query == acs_uri.query
        end
      rescue URI::InvalidURIError
        original_uri_match?(destination_url, settings_url)
      end

      def self.status_error_msg(error_msg, raw_status_code = nil, status_message = nil)
        unless raw_status_code.nil?
          if raw_status_code.include? "|"
            status_codes = raw_status_code.split(' | ')
            values = status_codes.collect do |status_code|
              status_code.split(':').last
            end
            printable_code = values.join(" => ")
          else
            printable_code = raw_status_code.split(':').last || ""
          end
          error_msg << ', was ' + printable_code
        end

        unless status_message.nil?
          error_msg << ' -> ' + status_message
        end

        error_msg
      end

    end
  end
end
