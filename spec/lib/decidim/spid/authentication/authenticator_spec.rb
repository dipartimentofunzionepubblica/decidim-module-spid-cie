# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Spid
    module Authentication
      describe Authenticator do
        subject { described_class.new(tenant, organization, oauth_hash) }

        let(:tenant) { Decidim::Spid.tenants.first }
        let(:organization) { create(:organization) }
        let(:oauth_hash) do
          {
            provider: oauth_provider,
            uid: oauth_uid,
            info: {
              email: oauth_email,
              name: oauth_name,
              first_name: oauth_first_name,
              last_name: oauth_last_name,
              image: oauth_image
            },
            extra: {
              raw_info: OneLogin::RubySaml::Attributes.new(saml_attributes)
            }
          }
        end
        let(:oauth_provider) { "provider" }
        let(:oauth_uid) { "uid" }
        let(:oauth_email) { nil }
        let(:oauth_first_name) { "Marja" }
        let(:oauth_last_name) { "Mainio" }
        let(:oauth_name) { "Marja Mainio" }
        let(:oauth_image) { nil }
        let(:saml_attributes) do
          {
            "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name" => [oauth_name],
            "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" => [oauth_email],
            "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname" => [oauth_first_name],
            "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname" => [oauth_last_name],
          }.delete_if { |_k, v| v.nil? }
        end

        describe "#verified_email" do
          context "when email is available in the OAuth info" do
            let(:oauth_email) { "user@example.org" }

            it "returns the email from SAML attributes" do
              expect(subject.verified_email).to eq("user@example.org")
            end
          end

        end

        describe "#user_params_from_oauth_hash" do
          it "returns the expected hash" do
            signature = ::Decidim::OmniauthRegistrationForm.create_signature(
              oauth_provider,
              oauth_uid
            )

            expect(subject.user_params_from_oauth_hash).to include(
              provider: oauth_provider,
              uid: oauth_uid,
              name: oauth_name,
              oauth_signature: signature,
              avatar_url: nil,
              raw_data: oauth_hash
            )
          end

          context "when oauth data is empty" do
            let(:oauth_hash) { {} }

            it "returns nil" do
              expect(subject.user_params_from_oauth_hash).to be_nil
            end
          end

          context "when user identifier is blank" do
            let(:oauth_uid) { nil }

            it "returns nil" do
              expect(subject.user_params_from_oauth_hash).to be_nil
            end
          end

        end

        describe "#validate!" do
          it "returns true for valid authentication data" do
            expect(subject.validate!).to be(true)
          end

          context "when an identity already exists" do
            let(:user) { create(:user, :confirmed, organization: organization) }
            let!(:identity) do
              user.identities.create!(
                organization: organization,
                provider: oauth_provider,
                uid: oauth_uid
              )
            end

            it "returns true for valid authentication data" do
              expect(subject.validate!).to be(true)
            end
          end

          context "when no SAML attributes are available" do
            let(:saml_attributes) { {} }

            it "raises a ValidationError" do
              expect do
                subject.validate!
              end.to raise_error(
                Decidim::Spid::Authentication::ValidationError,
                "No SAML data provided"
              )
            end
          end

          context "when all SAML attributes values are blank" do
            let(:saml_attributes) do
              {
                "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name" => [],
                "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" => [],
                "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname" => [],
                "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname" => [],
                "http://schemas.microsoft.com/identity/claims/displayname" => nil
              }
            end

            it "raises a ValidationError" do
              expect do
                subject.validate!
              end.to raise_error(
                Decidim::Spid::Authentication::ValidationError,
                "Invalid SAML data"
              )
            end
          end

          context "when there is no person identifier" do
            let(:oauth_uid) { nil }

            it "raises a ValidationError" do
              expect do
                subject.validate!
              end.to raise_error(
                Decidim::Spid::Authentication::ValidationError,
                "Invalid person dentifier"
              )
            end
          end
        end

        describe "#identify_user!" do
          let(:user) { create(:user, :confirmed, organization: organization) }

          it "creates a new identity for the user" do
            id = subject.identify_user!(user)

            expect(Decidim::Identity.count).to eq(1)
            expect(Decidim::Identity.last.id).to eq(id.id)
            expect(id.organization.id).to eq(organization.id)
            expect(id.user.id).to eq(user.id)
            expect(id.provider).to eq(oauth_provider)
            expect(id.uid).to eq(oauth_uid)
          end

          context "when an identity already exists" do
            let!(:identity) do
              user.identities.create!(
                organization: organization,
                provider: oauth_provider,
                uid: oauth_uid
              )
            end

            it "returns the same identity" do
              expect(subject.identify_user!(user).id).to eq(identity.id)
            end
          end

          context "when a matching identity already exists for another user" do
            let(:another_user) { create(:user, :confirmed, organization: organization) }

            before do
              another_user.identities.create!(
                organization: organization,
                provider: oauth_provider,
                uid: oauth_uid
              )
            end

            it "raises an IdentityBoundToOtherUserError" do
              expect do
                subject.identify_user!(user)
              end.to raise_error(
                Decidim::Spid::Authentication::IdentityBoundToOtherUserError
              )
            end
          end
        end

        describe "#authorize_user!" do
          let(:user) { create(:user, :confirmed, organization: organization) }
          let(:signature) do
            ::Decidim::OmniauthRegistrationForm.create_signature(
              oauth_provider,
              oauth_uid
            )
          end

          it "creates a new authorization for the user" do
            auth = subject.authorize_user!(user)

            expect(Decidim::Authorization.count).to eq(1)
            expect(Decidim::Authorization.last.id).to eq(auth.id)
            expect(auth.user.id).to eq(user.id)
            expect(auth.unique_id).to eq(signature)
          end

          context "when the metadata collector has been configured to collect attributes" do
            let(:saml_attributes) do
              {
                "name" => [oauth_first_name],
                "familyName" => [oauth_last_name],
                "fiscalNumber" => ["TINIT-LVLDAA85T50G702B"],
                "spidCode" => ["SPID-002"],
                "email" => [oauth_email],
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

            it "creates a new authorization for the user with the correct metadata" do
              auth = subject.authorize_user!(user)

              expect(Decidim::Authorization.count).to eq(1)
              expect(Decidim::Authorization.last.id).to eq(auth.id)
              expect(auth.user.id).to eq(user.id)
              expect(auth.unique_id).to eq(signature)
              expect(auth.metadata).to include(
                                         "name" => "Marja",
                                         "surname" => "Mainio",
                                         "fiscal_code" => "TINIT-LVLDAA85T50G702B",
                                         "gender" => "F",
                                         "birthday" => "1985-07-15",
                                         "birthplace" => "G702",
                                         "registered_office" => "",
                                         "iva_code" => "",
                                         "id_card" => "passaporto KK1234567 questuraLivorno 2016-09-04 2026-09-03",
                                         "mobile_phone" => "123456",
                                         "address" => "Via Listz 21 00144 Roma",
                                         "digital_address" => ""
              )
            end
          end

          context "when an authorization already exists" do
            let!(:authorization) do
              Decidim::Authorization.create!(
                name: "ciao_identity",
                user: user,
                unique_id: signature
              )
            end

            it "returns the existing authorization and updates it" do
              auth = subject.authorize_user!(user)

              expect(auth.id).to eq(authorization.id)
            end
          end

          context "when a matching authorization already exists for another user" do
            let(:another_user) { create(:user, :confirmed, organization: organization) }

            before do
              Decidim::Authorization.create!(
                name: "ciao_identity",
                user: another_user,
                unique_id: signature
              )
            end

            it "raises an IdentityBoundToOtherUserError" do
              expect do
                subject.authorize_user!(user)
              end.to raise_error(
                Decidim::Spid::Authentication::AuthorizationBoundToOtherUserError
              )
            end
          end
        end

        describe "#update_user!" do
          let(:oauth_email) { "omniauth@example.org" }

          let(:user) { create(:user, :confirmed, organization: organization) }
          let(:signature) do
            ::Decidim::OmniauthRegistrationForm.create_signature(
              oauth_provider,
              oauth_uid
            )
          end

          it "updates the user's email address in case it has changed" do
            subject.update_user!(user)

            expect(user.email).to eq(oauth_email)
          end

        end
      end
    end
  end
end
