# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

require 'onelogin/ruby-saml/validation_error'

# Personalizzazioni Logout request SAML
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