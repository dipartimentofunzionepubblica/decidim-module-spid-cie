# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

require 'decidim/spid/validations'

module Decidim
  module Spid
    class SsoResponse

      include Decidim::Spid::Validations

      attr_accessor :response, :sso_params, :authn_context

      def initialize saml_response, sso_params, options
        options["matches_request_id"] = sso_params.dig("uuid")
        response = OneLogin::RubySaml::Response.new(saml_response, options)
        settings = Settings::Sso.new(options.merge(idp: sso_params.dig("sso", "idp")))
        @authn_context = settings.settings[:authn_context].sub(/[1-3]$/, '')
        saml_settings = OneLogin::RubySaml::Settings.new(settings.settings)
        response.settings = saml_settings
        @sso_params = sso_params
        @response = response
      end

      def valid?
        @response.is_valid? && validate!
      end

      def inspect
        @response.inspect
      end

      def session_index
        @response.sessionindex
      end

      def session_expire_at
        @response.session_expires_at
      end

      def errors
        @response.errors
      end

      def key_level
        "spid_level"
      end

    end

  end
end