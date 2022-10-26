# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

require 'onelogin/ruby-saml'

# Only supports SAML 2.0
module OneLogin
  module RubySaml

    class Logoutrequest

      def create_xml_document(settings)
        time = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")

        request_doc = XMLSecurity::Document.new
        request_doc.uuid = uuid

        root = request_doc.add_element "samlp:LogoutRequest", { "xmlns:samlp" => "urn:oasis:names:tc:SAML:2.0:protocol", "xmlns:saml" => "urn:oasis:names:tc:SAML:2.0:assertion" }
        root.attributes['ID'] = uuid
        root.attributes['IssueInstant'] = time
        root.attributes['Version'] = "2.0"
        root.attributes['Destination'] = settings.idp_slo_service_url  unless settings.idp_slo_service_url.nil? or settings.idp_slo_service_url.empty?

        if settings.sp_entity_id
          issuer = root.add_element "saml:Issuer", {
            'NameQualifier' => settings.issuer,
            'Format' => 'urn:oasis:names:tc:SAML:2.0:nameid-format:entity'
          }
          issuer.text = settings.sp_entity_id
        end

        nameid = root.add_element "saml:NameID"
        if settings.name_identifier_value
          nameid.attributes['NameQualifier'] = settings.idp_name_qualifier if settings.idp_name_qualifier
          nameid.attributes['SPNameQualifier'] = settings.sp_name_qualifier if settings.sp_name_qualifier
          nameid.attributes['Format'] = settings.name_identifier_format if settings.name_identifier_format
          nameid.text = settings.name_identifier_value
        else
          # If no NameID is present in the settings we generate one
          nameid.text = OneLogin::RubySaml::Utils.uuid
          nameid.attributes['Format'] = 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
        end

        if settings.sessionindex
          sessionindex = root.add_element "samlp:SessionIndex"
          sessionindex.text = settings.sessionindex
        end

        request_doc
      end

    end
  end
end
