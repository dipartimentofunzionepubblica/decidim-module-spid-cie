# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Spid
    describe Tenant do
      context "with default configuration" do
        let(:subject) { described_class.new {} }

        describe "#name" do
          it "returns the default name when name is not configured" do
            expect(subject.name).to eq("spid")
          end
        end

        describe "#name=" do
          it "sets the name with correctly formatted name" do
            subject.name = "correct"
            expect(subject.name).to eq("correct")
          end

          it "raises an InvalidTenantName when the name contains invalid characters" do
            expect { subject.name = "name with spaces" }.to raise_error(Decidim::Spid::InvalidTenantName)
            expect { subject.name = "Name_With_Capitalization" }.to raise_error(Decidim::Spid::InvalidTenantName)
            expect { subject.name = "name-with-dashes" }.to raise_error(Decidim::Spid::InvalidTenantName)
            expect { subject.name = "name_with_number_123" }.to raise_error(Decidim::Spid::InvalidTenantName)
          end
        end

        describe "#authenticator_for" do
          let(:organization) { double }
          let(:oauth_hash) { double }

          it "initializes a new instance of the default authenticator class" do
            expect(Decidim::Spid::Authentication::Authenticator).to receive(
              :new
            ).with(instance_of(described_class), organization, oauth_hash)

            subject.authenticator_for(organization, oauth_hash)
          end

          context "when authenticator class is configured" do
            let(:authenticator_class) { double }

            it "initializes a new instance of the configured class" do
              expect(authenticator_class).to receive(:new).with(
                instance_of(described_class),
                organization,
                oauth_hash
              )

              subject.authenticator_class = authenticator_class
              subject.authenticator_for(organization, oauth_hash)
            end
          end
        end

        describe "#metadata_collector_for" do
          let(:saml_attributes) { double }

          it "initializes a new instance of the default authenticator class" do
            expect(Decidim::Spid::Verification::MetadataCollector).to receive(
              :new
            ).with(instance_of(described_class), saml_attributes)

            subject.metadata_collector_for(saml_attributes)
          end

          context "when authenticator class is configured" do
            let(:metadata_collector_class) { double }

            it "initializes a new instance of the configured class" do
              expect(metadata_collector_class).to receive(:new).with(
                instance_of(described_class),
                saml_attributes
              )

              subject.metadata_collector_class = metadata_collector_class
              subject.metadata_collector_for(saml_attributes)
            end
          end
        end
      end
    end
  end
end
