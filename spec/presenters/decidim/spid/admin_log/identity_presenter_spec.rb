# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Spid
    module AdminLog
      describe IdentityPresenter, type: :presenter do
        let(:organization) { create(:organization, available_locales: (Decidim.available_locales.map(&:to_s) | ["en", "it"])) }
        let(:user) { create(:user, organization: organization, locale: "en", name: "Mario Rossi") }
        let(:identity) { create(:identity, user: user, provider: "spid") }
        let(:timestamp_utc) { "2023-10-24 14:32:15.123 UTC" }
        let(:saml_transaction_id) { "_5c829f04-8b65-4d76-b681-42e584f29402" }
        let(:extra_data) do
          {
            "user" => {
              "name" => user.name,
              "nickname" => user.nickname
            },
            "resource" => {
              "title" => "SPID"
            },
            "timestamp_utc" => timestamp_utc,
            "saml_transaction_id" => saml_transaction_id
          }
        end
        let(:action_log) do
          Decidim::ActionLog.create!(
            action: action,
            user: user,
            resource: identity,
            organization: organization,
            extra: extra_data
          )
        end
        let(:view_context) do
          controller = Decidim::ApplicationController.new
          controller.request = ActionDispatch::TestRequest.create
          controller.request.env["decidim.current_organization"] = organization
          allow(controller).to receive(:current_organization).and_return(organization)
          allow(controller).to receive(:current_locale) { I18n.locale.to_s }
          controller.view_context
        end
        let(:presenter) { described_class.new(action_log, view_context) }

        describe "#present" do
          before(:each) do
            it_translations = YAML.load_file(File.expand_path("../../../../../config/locales/it.yml", __dir__))["it"]
            en_translations = YAML.load_file(File.expand_path("../../../../../config/locales/en.yml", __dir__))["en"]
            I18n.backend.store_translations(:it, it_translations)
            I18n.backend.store_translations(:en, en_translations)
          end

          around do |example|
            orig_available = I18n.available_locales
            I18n.available_locales = (Decidim.available_locales.map(&:to_sym) | [:en, :it])
            I18n.with_locale(:it) do
              example.run
            end
          ensure
            I18n.available_locales = orig_available
          end

          context "when action is login" do
            let(:action) { :login }

            it "presents the log message including UTC timestamp and SAML ID" do
              result = presenter.present
              expect(result).to include("Mario Rossi")
              expect(result).to include("SPID")
              expect(result).to include("[UTC: 2023-10-24 14:32:15.123 UTC, ID SAML: _5c829f04-8b65-4d76-b681-42e584f29402]")
            end
          end

          context "when action is registration" do
            let(:action) { :registration }

            it "presents the log message including UTC timestamp and SAML ID" do
              result = presenter.present
              expect(result).to include("Mario Rossi")
              expect(result).to include("SPID")
              expect(result).to include("[UTC: 2023-10-24 14:32:15.123 UTC, ID SAML: _5c829f04-8b65-4d76-b681-42e584f29402]")
            end
          end

          context "when action is logout" do
            let(:action) { :logout }

            it "presents the log message including UTC timestamp and SAML ID" do
              result = presenter.present
              expect(result).to include("Mario Rossi")
              expect(result).to include("SPID")
              expect(result).to include("[UTC: 2023-10-24 14:32:15.123 UTC, ID SAML: _5c829f04-8b65-4d76-b681-42e584f29402]")
            end
          end

          context "when extra data lacks timestamp or saml_transaction_id (backward compatibility)" do
            let(:action) { :login }
            let(:extra_data) do
              {
                "user" => {
                  "name" => user.name,
                  "nickname" => user.nickname
                },
                "resource" => {
                  "title" => "SPID"
                }
              }
            end

            it "handles missing extra fields gracefully without crashing" do
              result = presenter.present
              expect(result).to include("Mario Rossi")
              expect(result).to include("SPID")
            end
          end

          context "in English locale" do
            let(:action) { :login }

            it "presents the log message in English with UTC timestamp and SAML ID" do
              I18n.with_locale(:en) do
                result = presenter.present
                expect(result).to include("logged in with provider")
                expect(result).to include("[UTC: 2023-10-24 14:32:15.123 UTC, SAML ID: _5c829f04-8b65-4d76-b681-42e584f29402]")
              end
            end
          end
        end
      end
    end
  end
end
