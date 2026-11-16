# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Cie
    module Authentication
      describe Authenticator do
        let(:tenant) { Decidim::Cie.tenants.first }
        let(:organization) { create(:organization, host: URI(tenant.sp_entity_id).host) }
        let(:user) { create(:user, organization: organization) }
        let(:uid) { "CIE-12345" }
        let(:saml_transaction_id) { "_9c829f04-8b65-4d76-b681-42e584f29499" }
        let(:raw_info) do
          {
            "name" => ["Giulia"],
            "familyName" => ["Bianchi"],
            "fiscalNumber" => ["TINIT-BNCGLI85T50G702B"],
            "spidCode" => [uid],
            "email" => ["giulia.bianchi@example.org"],
            "gender" => ["F"],
            "dateOfBirth" => ["1985-12-10"],
            "placeOfBirth" => ["G702"],
            "address" => ["Via Milano 10"],
            "mobilePhone" => ["3339876543"]
          }
        end
        let(:oauth_hash) do
          {
            provider: "cie",
            uid: uid,
            info: {
              name: "Giulia Bianchi",
              email: "giulia.bianchi@example.org"
            },
            extra: {
              raw_info: raw_info,
              saml_transaction_id: saml_transaction_id
            }
          }
        end
        let(:authenticator) { described_class.new(tenant, organization, oauth_hash) }

        describe "#identify_user!" do
          context "when identity exists (login)" do
            let!(:identity) { create(:identity, user: user, provider: "cie", uid: uid, organization: organization) }

            it "logs the login action in Decidim::ActionLog with UTC millisecond timestamp and SAML transaction id" do
              expect do
                identified_identity = authenticator.identify_user!(user)
                expect(identified_identity).to eq(identity)
              end.to change { Decidim::ActionLog.where(action: "login").count }.by(1)

              action_log = Decidim::ActionLog.where(action: "login").last
              expect(action_log.user).to eq(user)
              expect(action_log.resource).to eq(identity)
              expect(action_log.extra["timestamp_utc"]).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/)
              expect(action_log.extra["saml_transaction_id"]).to eq(saml_transaction_id)
            end
          end

          context "when user has no identity yet (bind identity)" do
            it "binds the identity and logs the registration action with metadata" do
              expect do
                identified_identity = authenticator.identify_user!(user)
                expect(identified_identity.user).to eq(user)
              end.to change { Decidim::ActionLog.where(action: "registration").count }.by(1)

              action_log = Decidim::ActionLog.where(action: "registration").last
              expect(action_log.user).to eq(user)
              expect(action_log.extra["timestamp_utc"]).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/)
              expect(action_log.extra["saml_transaction_id"]).to eq(saml_transaction_id)
            end
          end
        end
      end
    end
  end
end
