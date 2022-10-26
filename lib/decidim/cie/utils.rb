# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

module Decidim
  module Cie
    module Utils

      cattr_accessor :current_name, default: ''

      def metadata_xml(overrides = {})
        metadata = Decidim::Cie::Metadata.new
        metadata.to_xml(Decidim::Cie::Settings::Metadata.new(overrides))
      end

      def sso_saml(sso_params, options)
        request = Decidim::Cie::SsoRequest.new(sso_params, options)
        session[:"tenant-cie-name"] = options["name"]
        session[:"#{session_prefix}sso_params"] = sso_params.merge(
          issue_instant: request.issue_instant,
          uuid: request.uuid)
        request.to_saml
      end

      def slo_saml(slo_params, options)
        logout_request = Decidim::Cie::SloRequest.new(slo_params, options)
        session[:"#{session_prefix}slo_id"] = logout_request.uuid
        logout_request.to_saml
      end

      def sso_request(saml_response, options)
        r = Decidim::Cie::SsoResponse.new(saml_response, session[:"#{session_prefix}sso_params"], options)
        response = r.response
        valid = r.valid?
        if valid
          session[:"#{session_prefix}uid"] = response.attributes[options.uid_attribute] || response.name_id.try(:strip)
          session[:"#{session_prefix}index"] = r.session_index
          session[:"#{session_prefix}login_time"] = Time.now
          msg = 'decidim.cie.sso_request.success'
        else
          matches = nil
          if r.errors && r.errors.any?{ |a| matches = a.match(/The status code of the Response was not Success, was Responder => AuthnFailed -> ErrorCode nr(19|2[1-5])/) } && (error_code = matches.try(:[], 1)).present?
            msg = "decidim.cie.sso_request.failure_#{error_code}"
          else
            msg = 'decidim.cie.sso_request.failure'
          end
        end
        [valid, msg, response]
      end

      def slo_request(saml_response, options)
        response = Decidim::Cie::SloResponse.new(saml_response, session[:"#{session_prefix}sso_params"].merge(slo_id: session[:"#{session_prefix}slo_id"]), options)
        valid = response.valid?
        if valid
          session.delete(:"#{session_prefix}sso_params")
          session.delete(:"#{session_prefix}index")
          session.delete(:"#{session_prefix}slo_id")
          session.delete(:"#{session_prefix}relay_state")
          session.delete(:"#{session_prefix}login_time")
          msg = 'decidim.cie.slo_request.success'
        else
          msg = 'decidim.cie.slo_request.failure'
        end
        [valid, msg]
      end

      def slo_params
        sso_params = {}
        sso_params[:sso] = { idp: session[:"#{session_prefix}sso_params"].dig("sso", "idp") }
        sso_params[:cie_level] = session[:"#{session_prefix}sso_params"]["cie_level"]
        sso_params[:session_index] = session[:"#{session_prefix}index"]
        sso_params[:relay_state] = Base64.strict_decode64(session[:"#{session_prefix}sso_params"]["relay_state"])
        sso_params
      end

      def session_prefix
        options["name"] + '_cie_'
      end

    end
  end
end