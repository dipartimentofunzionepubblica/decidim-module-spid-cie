# frozen_string_literal: true

require "omniauth/strategies/cie_saml"

require_relative "cie/engine"
require_relative "cie/admin"
require_relative "cie/admin_engine"
require_relative "cie/authentication"
require_relative "cie/verification"
require_relative "cie/component"

module Decidim
  # This namespace holds the logic of the `Cie` component. This component
  # allows users to create cie in a participatory space.
  module Cie
    autoload :Tenant, "decidim/cie/tenant"

    class << self
      def tenants
        @tenants ||= []
      end

      def test!
        @test = true
      end

      def configure(&block)
        tenant = Decidim::Cie::Tenant.new(&block)
        tenants.each do |existing|
          if tenant.name == existing.name
            raise(
              TenantSameName,
              "Please define an individual name for the Cie tenant. The name \"#{tenant.name}\" is already in use."
            )
          end

          match = tenant.name =~ /^#{existing.name}/
          match ||= existing.name =~ /^#{tenant.name}/
          next unless match

        end

        tenants << tenant
      end

      def setup!
        raise "Cie module is already initialized!" if initialized?

        @initialized = true
        tenants.each(&:setup!)
      end

      def find_tenant(name)
        Decidim::Cie.tenants.select { |a| a.name == name}.try(:first)
      end

      private

      def initialized?
        @initialized
      end
    end

    class TenantSameName < StandardError; end

    class InvalidTenantName < StandardError; end
  end
end
