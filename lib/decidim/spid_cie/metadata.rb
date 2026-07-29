require "onelogin/ruby-saml/metadata"

module Decidim
  module SpidCie
    #
    class Metadata < ::OneLogin::RubySaml::Metadata

      def add_root_element(meta_doc, settings, valid_until, cache_duration)
        namespaces = {
          "xmlns:md" => "urn:oasis:names:tc:SAML:2.0:metadata"
        }

        if (settings.attribute_consuming_service.is_a?(Array) && settings.attribute_consuming_service.present?) || settings.attribute_consuming_service.configured?
          namespaces["xmlns:saml"] = "urn:oasis:names:tc:SAML:2.0:assertion"
        end

        root = meta_doc.add_element("md:EntityDescriptor", namespaces)
        root.attributes["ID"] = OneLogin::RubySaml::Utils.uuid
        root.attributes["entityID"] = settings.sp_entity_id if settings.sp_entity_id
        root.attributes["validUntil"] = valid_until.utc.strftime('%Y-%m-%dT%H:%M:%SZ') if valid_until
        root.attributes["cacheDuration"] = "PT" + cache_duration.to_s + "S" if cache_duration
        root
      end

      def add_sp_service_elements(sp_sso, settings)
        if settings.single_logout_service_url
          sp_sso.add_element "md:SingleLogoutService", {
            "Binding" => settings.single_logout_service_binding,
            "Location" => settings.single_logout_service_url,
            "ResponseLocation" => settings.single_logout_service_url
          }
        end

        if settings.logout_services.present?
          settings.logout_services.each_with_index do |ls, index|
            sp_sso.add_element "md:SingleLogoutService", {
              "Binding" => ls['Binding'],
              "Location" => ls['Location']
            }.merge(ls['ResponseLocation'] ? { "ResponseLocation" => ls['ResponseLocation'] } : {})
          end
        end

        if settings.name_identifier_format
          nameid = sp_sso.add_element "md:NameIDFormat"
          nameid.text = settings.name_identifier_format
        end

        if settings.assertion_consumer_service_url
          sp_sso.add_element "md:AssertionConsumerService", {
            "Binding" => settings.assertion_consumer_service_binding,
            "Location" => settings.assertion_consumer_service_url,
            "isDefault" => true,
            "index" => 0
          }
        end

        if settings.consumer_services.present?
          settings.consumer_services.each_with_index do |cs, index|
            if settings.try(:default_service_index)
              dcs = settings.default_service_index == index ? { "isDefault" => settings.default_service_index == index } : {}
            else
              dcs = 0 == index ? { "isDefault" => true } : {}
            end
            sp_sso.add_element "md:AssertionConsumerService", {
              "Binding" => cs['Binding'],
              "Location" => cs['Location'],
              "index" => index
            }.merge(dcs)

          end
        end

        if settings.attribute_consuming_service.is_a?(Array) && settings.attribute_consuming_service.present?
          settings.attribute_consuming_service.each_with_index do |fields, index|
            sp_acs = sp_sso.add_element "md:AttributeConsumingService", {
              "isDefault" => index == 0,
              "index" => index
            }
            srv_name = sp_acs.add_element "md:ServiceName", {
              "xml:lang" => "it"
            }
            srv_name.text = settings.attribute_service_names[index] || "Set #{index}"
            fields.each do |attribute|
              sp_req_attr = sp_acs.add_element "md:RequestedAttribute", {
                "NameFormat" => attribute[:name_format],
                "Name" => attribute[:name],
                "FriendlyName" => attribute[:friendly_name],
                "isRequired" => attribute[:is_required] || false
              }
              unless attribute[:attribute_value].nil?
                Array(attribute[:attribute_value]).each do |value|
                  sp_attr_val = sp_req_attr.add_element "saml:AttributeValue"
                  sp_attr_val.text = value.to_s
                end
              end
            end
          end
        else
          settings.attribute_consuming_service.configured?
          sp_acs = sp_sso.add_element "md:AttributeConsumingService", {
            "isDefault" => "true",
            "index" => settings.attribute_consuming_service.index
          }
          srv_name = sp_acs.add_element "md:ServiceName", {
            "xml:lang" => "en"
          }
          srv_name.text = settings.attribute_consuming_service.name
          settings.attribute_consuming_service.attributes.each do |attribute|
            sp_req_attr = sp_acs.add_element "md:RequestedAttribute", {
              "NameFormat" => attribute[:name_format],
              "Name" => attribute[:name],
              "FriendlyName" => attribute[:friendly_name],
              "isRequired" => attribute[:is_required] || false
            }
            unless attribute[:attribute_value].nil?
              Array(attribute[:attribute_value]).each do |value|
                sp_attr_val = sp_req_attr.add_element "saml:AttributeValue"
                sp_attr_val.text = value.to_s
              end
            end
          end
        end

        # With OpenSSO, it might be required to also include
        #  <md:RoleDescriptor xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:query="urn:oasis:names:tc:SAML:metadata:ext:query" xsi:type="query:AttributeQueryDescriptorType" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol"/>
        #  <md:XACMLAuthzDecisionQueryDescriptor WantAssertionsSigned="false" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol"/>

        sp_sso
      end

      def add_extras(root, _settings)
        org = root.add_element("md:Organization")
        _settings.organization.each do |k, h|
          org.add_element("md:OrganizationName", 'xml:lang' => k).text = h[:name]
          org.add_element("md:OrganizationDisplayName", 'xml:lang' => k).text = h[:display]
          org.add_element("md:OrganizationURL", 'xml:lang' => k).text = h[:url]
        end

        v = _settings.respond_to?(:contact_people_other) ? _settings.contact_people_other : []
        if v.present?
          cp = root.add_element("md:ContactPerson", 'contactType' => 'other')
          ce = cp.add_element("md:Extensions")
          ce.add_namespace('spid', 'https://spid.gov.it/saml-extensions')
          ce.add_element("spid:IPACode").text = v[:ipa_code] if v[:ipa_code]
          ce.add_element("spid:VATNumber").text = v[:vat_number] if v[:vat_number]
          ce.add_element("spid:FiscalCode").text = v[:fiscal_code] if v[:fiscal_code]
          v[:public] ? ce.add_element("spid:Public") : ce.add_element("spid:Private")
          cp.add_element("md:Company").text = v[:company] if v[:company]
          cp.add_element("md:EmailAddress").text = v[:email] if v[:email]
          cp.add_element("md:TelephoneNumber").text = v[:number] if v[:number]
        end

        # <md:ContactPerson contactType="billing">
        # <md:Extensions>
        #   <fpa:CessionarioCommittente>
        #     <fpa:DatiAnagrafici>
        #       <fpa:IdFiscaleIVA>
        #         <fpa:IdPaese>IT</fpa:IdPaese>
        #         <fpa:IdCodice>983745349857</fpa:IdCodice>
        #       </fpa:IdFiscaleIVA>
        #       <fpa:Anagrafica>
        #         <fpa:Denominazione>Destinatario Fatturazione</fpa:Denominazione>
        #       </fpa:Anagrafica>
        #     </fpa:DatiAnagrafici>
        #     <fpa:Sede>
        #       <fpa:Indirizzo>via tante cose</fpa:Indirizzo>
        #       <fpa:NumeroCivico>12</fpa:NumeroCivico>
        #       <fpa:CAP>87100</fpa:CAP>
        #       <fpa:Comune>Cosenza</fpa:Comune>
        #       <fpa:Provincia>CS</fpa:Provincia>
        #       <fpa:Nazione>IT</fpa:Nazione>
        #     </fpa:Sede>
        #   </fpa:CessionarioCommittente>
        # </md:Extensions>
        # <md:Company>example s.p.a.</md:Company>
        # <md:EmailAddress>info@example.org</md:EmailAddress>
        # <md:TelephoneNumber>+39 84756344785</md:TelephoneNumber>
        # </md:ContactPerson>

        c = _settings.respond_to?(:contact_people_billing) ? _settings.contact_people_billing : []
        if c.present?
          cp = root.add_element("md:ContactPerson", 'contactType' => 'billing')
          ce = cp.add_element("md:Extensions")
          ce.add_namespace('fpa', 'https://spid.gov.it/invoicing-extensions')
          cc = ce.add_element("fpa:CessionarioCommittente")
          da = cc.add_element("fpa:DatiAnagrafici")
          idi = da.add_element("fpa:IdFiscaleIVA")
          idi.add_element("fpa:IdPaese").text = c[:id_paese] if c[:id_paese]
          idi.add_element("fpa:IdCodice").text = c[:id_codice] if c[:id_codice]
          a = da.add_element("fpa:Anagrafica")
          a.add_element("fpa:Denominazione").text = c[:denominazione] if c[:denominazione]
          s = cc.add_element("fpa:Sede")
          s.add_element("fpa:Indirizzo").text = c[:indirizzo] if c[:indirizzo]
          s.add_element("fpa:NumeroCivico").text = c[:numero_civico] if c[:numero_civico]
          s.add_element("fpa:CAP").text = c[:cap] if c[:cap]
          s.add_element("fpa:Comune").text = c[:comune] if c[:comune]
          s.add_element("fpa:Provincia").text = c[:provincia] if c[:provincia]
          s.add_element("fpa:Nazione").text = c[:nazione] if c[:nazione]
          cp.add_element("md:Company").text = c[:company] if c[:company]
          cp.add_element("md:EmailAddress").text = c[:email] if c[:email]
          cp.add_element("md:TelephoneNumber").text = c[:number] if c[:number]
        end

      end

    end
  end
end