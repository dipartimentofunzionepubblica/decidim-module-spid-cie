# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Spid
    module Authentication
      describe Authenticator do
        let(:tenant) { Decidim::Spid.tenants.first }
        let(:organization) { create(:organization, host: URI(tenant.sp_entity_id).host) }
        let(:user) { create(:user, organization: organization) }
        let(:uid) { "SPID-12345" }
        let(:saml_transaction_id) { "_5c829f04-8b65-4d76-b681-42e584f29402" }
        let(:raw_info) do
          {
            "name" => ["Mario"],
            "familyName" => ["Rossi"],
            "fiscalNumber" => ["TINIT-RSSMRA80A01H501Z"],
            "spidCode" => [uid],
            "email" => ["mario.rossi@example.org"],
            "gender" => ["M"],
            "dateOfBirth" => ["1980-01-01"],
            "placeOfBirth" => ["H501"],
            "address" => ["Via Roma 1"],
            "mobilePhone" => ["3331234567"]
          }
        end
        let(:oauth_hash) do
          {
            provider: "spid",
            uid: uid,
            info: {
              name: "Mario Rossi",
              email: "mario.rossi@example.org"
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
            let!(:identity) { create(:identity, user: user, provider: "spid", uid: uid, organization: organization) }

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
