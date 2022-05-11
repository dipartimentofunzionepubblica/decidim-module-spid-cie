# frozen_string_literal: true

module Decidim
  module Cie
    module Verification
      # This is an engine that performs user authorization.
      class Engine < ::Rails::Engine
        isolate_namespace Decidim::Cie::Verification

        paths["db/migrate"] = nil
        paths["lib/tasks"] = nil

        routes do
          resource :authorizations, only: [:new], as: :authorization

          root to: "authorizations#new"
        end

        initializer "decidim_cie.verification_workflow", after: :load_config_initializers do
          Decidim::Cie.tenants.each do |tenant|
            Decidim::Verifications.register_workflow("#{tenant.name}_identity".to_sym) do |workflow|
              workflow.engine = Decidim::Cie::Verification::Engine
              tenant.workflow_configurator.call(workflow)
            end
          end
        end

        def load_seed
          Decidim::Cie.tenants.each do |tenant|
            # Enable the authorizations for each tenant
            org = Decidim::Organization.first
            org.available_authorizations << "#{tenant.name}_identity".to_sym
            org.save!
          end
        end
      end
    end
  end
end