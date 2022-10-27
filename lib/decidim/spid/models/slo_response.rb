# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Personalizzazioni response Logout SAML
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