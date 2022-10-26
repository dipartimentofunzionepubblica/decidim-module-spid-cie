# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

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

      def issue_instant
        @request.issue_instant
      end

      def uuid
        @request.uuid
      end

    end

  end
end