module Decidim
  module SpidCie
    autoload :Tenant, "decidim/spid_cie/tenant"

    def self.tenants
      @tenants ||= Decidim::Cie.tenants + Decidim::Spid.tenants
    end

  end
end
