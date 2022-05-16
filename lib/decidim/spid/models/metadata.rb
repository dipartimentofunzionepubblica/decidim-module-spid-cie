module Decidim
  module Spid
    class Metadata < OneLogin::RubySaml::Metadata

      attr_accessor :c_settings

      def add_extras(root, _settings)
        org = root.add_element("md:Organization")
        c_settings.organization.each do |k, h|
          org.add_element("md:OrganizationName", 'xml:lang' => k).text = h[:name]
          org.add_element("md:OrganizationDisplayName", 'xml:lang' => k).text = h[:display]
          org.add_element("md:OrganizationURL", 'xml:lang' => k).text = h[:url]
        end

        v = c_settings.contact_people_other
        if v.present?
          cp = root.add_element("md:ContactPerson", 'contactType' => 'other')
          ce = cp.add_element("md:Extensions")
          ce.add_namespace('spid', 'https://spid.gov.it/saml-extensions')
          ce.add_element("spid:IPACode").text = v[:ipa_code] if v[:ipa_code]
          ce.add_element("spid:VATNumber").text = v[:vat_number] if v[:vat_number]
          ce.add_element("spid:FiscalCode").text = v[:fiscal_code] if v[:fiscal_code]
          v[:public] ? ce.add_element("spid:Public") : ce.add_element("spid:Private")
          cp.add_element("md:Company").text = v[:company] if v[:company]
          cp.add_element("md:GivenName").text = v[:givenName] if v[:givenName]
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

        c = c_settings.contact_people_billing
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
          cp.add_element("md:GivenName").text = c[:givenName] if c[:givenName]
          cp.add_element("md:EmailAddress").text = c[:email] if c[:email]
          cp.add_element("md:TelephoneNumber").text = c[:number] if c[:number]
        end

      end

      def to_xml(settings)
        @c_settings = settings
        if settings.valid?
          saml_settings = OneLogin::RubySaml::Settings.new(settings.settings)
          saml_settings.attribute_consuming_service.configure do
            @index = 0
            @name = "Set 0"
            @attributes = settings.fields
          end
          self.generate(saml_settings)
        else
          raise OneLogin::RubySaml::ValidationError, settings.errors.try(:first)
        end
      end

    end
  end
end