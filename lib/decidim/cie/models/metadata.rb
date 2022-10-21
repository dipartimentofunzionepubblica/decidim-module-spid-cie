module Decidim
  module Cie
    class Metadata < OneLogin::RubySaml::Metadata

      attr_accessor :c_settings

      def add_extras(root, _settings)
        org = root.add_element("md:Organization")
        c_settings.organization.each do |k, h|
          org.add_element("md:OrganizationName", 'xml:lang' => k).text = h[:name]
          org.add_element("md:OrganizationDisplayName", 'xml:lang' => k).text = h[:display]
          org.add_element("md:OrganizationURL", 'xml:lang' => k).text = h[:url]
        end

        v = c_settings.respond_to?(:contact_people_administrative) ? c_settings.contact_people_administrative : []
        if v.present?
          cp = root.add_element("md:ContactPerson", 'contactType' => 'administrative')
          ce = cp.add_element("md:Extensions")
          ce.add_namespace('cie', 'https://www.cartaidentita.interno.gov.it/saml-extensions')
          v[:public] ? ce.add_element("cie:Public") : ce.add_element("cie:Private")
          ce.add_element("cie:IPACode").text = v[:ipa_code] if v[:ipa_code]
          ce.add_element("cie:VATNumber").text = v[:vat_number] if v[:vat_number] && !v[:public]
          ce.add_element("cie:FiscalCode").text = v[:fiscal_code] if v[:fiscal_code] && !v[:public]
          ce.add_element("cie:NACE2Code").text = v[:ateco_code] if v[:ateco_code] && !v[:public]
          ce.add_element("cie:Municipality").text = v[:municipality] if v[:municipality]
          ce.add_element("cie:Province").text = v[:province] if v[:province]
          ce.add_element("cie:Country").text = v[:country] if v[:country]
          cp.add_element("md:Company").text = v[:company] if v[:company]
          cp.add_element("md:EmailAddress").text = v[:email] if v[:email]
          cp.add_element("md:TelephoneNumber").text = v[:number] if v[:number]
        end

        v = c_settings.respond_to?(:contact_people_technical) ? c_settings.contact_people_technical : []
        if v.present?
          cp = root.add_element("md:ContactPerson", 'contactType' => 'technical')
          ce = cp.add_element("md:Extensions")
          ce.add_namespace('cie', 'https://www.cartaidentita.interno.gov.it/saml-extensions')
          v[:public] ? ce.add_element("cie:Public") : ce.add_element("cie:Private")
          ce.add_element("cie:IPACode").text = v[:ipa_code] if v[:ipa_code]
          ce.add_element("cie:VATNumber").text = v[:vat_number] if v[:vat_number] && !v[:public]
          ce.add_element("cie:FiscalCode").text = v[:fiscal_code] if v[:fiscal_code] && !v[:public]
          ce.add_element("cie:NACE2Code").text = v[:ateco_code] if v[:ateco_code] && !v[:public]
          ce.add_element("cie:Municipality").text = v[:municipality] if v[:municipality]
          ce.add_element("cie:Province").text = v[:province] if v[:province]
          ce.add_element("cie:Country").text = v[:country] if v[:country]
          cp.add_element("md:Company").text = v[:company] if v[:company]
          cp.add_element("md:EmailAddress").text = v[:email] if v[:email]
          cp.add_element("md:TelephoneNumber").text = v[:number] if v[:number]
        end

      end

      def to_xml(settings)
        @c_settings = settings
        if settings.valid?
          saml_settings = OneLogin::RubySaml::Settings.new(settings.settings)
          unless saml_settings.attribute_consuming_service.is_a?(Array)
            saml_settings.attribute_consuming_service.configure do
              @index = 0
              @name = "Set 0"
              @attributes = settings.fields
            end
          end
          self.generate(saml_settings)
        else
          raise OneLogin::RubySaml::ValidationError, settings.errors.try(:first)
        end
      end

    end
  end
end