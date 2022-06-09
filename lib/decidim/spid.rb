# frozen_string_literal: true

require 'deface'
require "omniauth/strategies/spid_saml"

require_relative "spid/version"
require_relative "spid/engine"
require_relative "spid/admin"
require_relative "spid/admin_engine"
require_relative "spid/authentication"
require_relative "spid/verification"
require_relative "spid/component"

require_relative "cie"

module Decidim
  # This namespace holds the logic of the `Spid` component. This component
  # allows users to create spid in a participatory space.
  module Spid
    autoload :Tenant, "decidim/spid/tenant"

    class << self
      def tenants
        @tenants ||= []
      end

      def test!
        @test = true
      end

      def configure(&block)
        tenant = Decidim::Spid::Tenant.new(&block)
        tenants.each do |existing|
          if tenant.name == existing.name
            raise(
              TenantSameName,
              "Please define an individual name for the Spid tenant. The name \"#{tenant.name}\" is already in use."
            )
          end

          match = tenant.name =~ /^#{existing.name}/
          match ||= existing.name =~ /^#{tenant.name}/
          next unless match

        end

        tenants << tenant
      end

      def setup!
        raise "Spid module is already initialized!" if initialized?

        @initialized = true
        tenants.each(&:setup!)
      end

      def find_tenant(name)
        Decidim::Spid.tenants.select { |a| a.name == name}.try(:first)
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
