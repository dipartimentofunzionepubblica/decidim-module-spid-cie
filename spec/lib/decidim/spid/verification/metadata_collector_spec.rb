# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Spid
    module Verification
      describe MetadataCollector do
        subject { described_class.new(tenant, OneLogin::RubySaml::Attributes.new(saml_attributes)) }

        let(:tenant) { Decidim::Spid.tenants.first }
        let(:oauth_provider) { "provider" }
        let(:oauth_uid) { "uid" }
        let(:oauth_email) { nil }
        let(:oauth_first_name) { "Marja" }
        let(:oauth_last_name) { "Mainio" }
        let(:oauth_name) { "Marja Mainio" }
        let(:oauth_nickname) { "mmainio" }

        let(:saml_attributes) do
          {
            "name" => [oauth_first_name],
            "familyName" => [oauth_last_name],
            "fiscalNumber" => ["TINIT-LVLDAA85T50G702B"],
            "spidCode" => ["SPID-002"],
            "email" => ['user@example.org'],
            "gender" => ["F"],
            "dateOfBirth" => ["1985-07-15"],
            "placeOfBirth" => ["G702"],
            "registeredOffice" => [""],
            "ivaCode" => [""],
            "idCard" => ["passaporto KK1234567 questuraLivorno 2016-09-04 2026-09-03"],
            "mobilePhone" => ["123456"],
            "address" => ["Via Listz 21 00144 Roma"],
            "digitalAddress" => [""],
            "fingerprint" => "EF:DE:F0:ED:5D:55:7A:3D:0D:4B:BD:5D:C9:3C:EE:07:DF:F9:5F:CB"
          }
        end

        context "when the module has not been configured to collect the metadata" do
          before do
            tenant.metadata_attributes = {}
          end

          it "does not collect any metadata" do
            expect(subject.metadata).to be(nil)
          end
        end

        context "when the module has been configured to collect the metadata" do
          before do
            tenant.metadata_attributes = {
              name: "name",
              surname: "familyName",
              fiscal_code: 'fiscalNumber',
              gender: 'gender',
              birthday: 'dateOfBirth',
              birthplace: "placeOfBirth",
              company_name: "companyName",
              registered_office: "registeredOffice",
              iva_code: "ivaCode",
              id_card: 'idCard',
              mobile_phone: 'mobilePhone',
              email: 'email',
              address: 'address',
              digital_address: 'digitalAddress'
            }
          end

          after do
            tenant.metadata_attributes = {}
          end

          it "collects the correct metadata" do
            expect(subject.metadata).to include(
                                          name: "Marja",
                                          surname: "Mainio",
                                          fiscal_code: "TINIT-LVLDAA85T50G702B",
                                          gender: "F",
                                          birthday: "1985-07-15",
                                          birthplace: "G702",
                                          registered_office: "",
                                          iva_code: "",
                                          id_card: "passaporto KK1234567 questuraLivorno 2016-09-04 2026-09-03",
                                          mobile_phone: "123456",
                                          email: "user@example.org",
                                          address: "Via Listz 21 00144 Roma",
                                          digital_address: ""
                                        )
          end
        end
      end
    end
  end
end
