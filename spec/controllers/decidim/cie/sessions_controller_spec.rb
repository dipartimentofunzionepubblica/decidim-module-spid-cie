# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Cie
    describe SessionsController, type: :controller do
      routes { Decidim::Cie::Engine.routes }

      let(:tenant) { Decidim::Cie.tenants.first }
      let(:organization) do
        create(
          :organization,
          host: URI(tenant.sp_entity_id).host,
          omniauth_settings: {
            "spid" => { "enabled" => true, "tenant_name" => "ciao" },
            "cie" => { "enabled" => true, "tenant_name" => "cie" }
          }
        )
      end
      let(:user) { create(:user, :confirmed, organization: organization) }
      let!(:spid_identity) { create(:identity, user: user, provider: "spid", uid: "SPID-12345", organization: organization) }
      let!(:cie_identity) { create(:identity, user: user, provider: "cie", uid: "CIE-12345", organization: organization) }
      let(:saml_transaction_id) { "_logout-uuid-cie-98765" }

      before do
        request.env["decidim.current_organization"] = organization
        request.env["devise.mapping"] = ::Devise.mappings[:user]
        allow(organization).to receive(:enabled_omniauth_providers).and_return({ spid: { tenant_name: "ciao" }, cie: { tenant_name: "cie" } })
        allow(controller).to receive(:current_organization).and_return(organization)
        sign_in user
      end

      describe "DELETE destroy" do
        context "when signed in with CIE" do
          before do
            session["decidim-cie.signed_in"] = true
            session[:"cie-uid"] = "CIE-12345"
            session["saml_transaction_id"] = saml_transaction_id
          end

          it "logs the logout action with UTC millisecond timestamp and SAML transaction id" do
            expect do
              delete :destroy
            end.to change { Decidim::ActionLog.where(action: "logout").count }.by(1)

            action_log = Decidim::ActionLog.where(action: "logout").last
            expect(action_log.user).to eq(user)
            expect(action_log.resource).to eq(cie_identity)
            expect(action_log.extra["timestamp_utc"]).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/)
            expect(action_log.extra["saml_transaction_id"]).to eq(saml_transaction_id)
            expect(action_log.extra.dig("resource", "title")).to eq("CIE")
          end
        end

        context "when signed in with SPID" do
          before do
            session["decidim-spid.signed_in"] = true
            session[:"spid-uid"] = "SPID-12345"
            session["saml_transaction_id"] = saml_transaction_id
          end

          it "logs the logout action with UTC millisecond timestamp and SAML transaction id" do
            expect do
              delete :destroy
            end.to change { Decidim::ActionLog.where(action: "logout").count }.by(1)

            action_log = Decidim::ActionLog.where(action: "logout").last
            expect(action_log.user).to eq(user)
            expect(action_log.resource).to eq(spid_identity)
            expect(action_log.extra["timestamp_utc"]).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/)
            expect(action_log.extra["saml_transaction_id"]).to eq(saml_transaction_id)
            expect(action_log.extra.dig("resource", "title")).to eq("SPID")
          end
        end
      end
    end
  end
end
