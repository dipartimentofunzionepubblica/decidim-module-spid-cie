require 'onelogin/ruby-saml'
# require "onelogin/ruby-saml/logging"
# require "onelogin/ruby-saml/saml_message"
# require "onelogin/ruby-saml/utils"
# require "onelogin/ruby-saml/setting_error"

# Only supports SAML 2.0
module OneLogin
  module RubySaml

    # SAML2 Logout Request (SLO SP initiated, Builder)
    #
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
