# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

require "uri"

require "onelogin/ruby-saml/logging"
require "onelogin/ruby-saml/utils"

# Necessario override per supportare multipli AttributeConsumingService, SingleLogoutService

module OneLogin
  module RubySaml

    # SAML2 Metadata. XML Metadata Builder
    #
    class Metadata

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
        root.attributes["validUntil"] = valid_until.strftime('%Y-%m-%dT%H:%M:%S%z') if valid_until
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
            }.merge( ls['ResponseLocation'] ? { "ResponseLocation" => ls['ResponseLocation'] } : {} )
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
            sp_sso.add_element "md:AssertionConsumerService", {
              "Binding" => cs['Binding'],
              "Location" => cs['Location'],
              "index" => index
            }.merge( settings.default_service_index == index ? { "isDefault" => settings.default_service_index == index} : {} )

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
        else settings.attribute_consuming_service.configured?
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

    end
  end
end
