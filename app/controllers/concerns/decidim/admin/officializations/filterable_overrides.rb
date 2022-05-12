module Decidim
  module Admin
    module Officializations
      module FilterableOverrides

        extend ActiveSupport::Concern

        included do
          include Decidim::Admin::Filterable

          private

          def base_query
            c = collection
            spid_filter = to_boolean(ransack_params.delete(:spid_presence))
            if !spid_filter.nil?
              if spid_filter
                c = c.left_joins(:identities).where(decidim_identities: { id: spid_ids })
              else
                c = c.left_joins(:identities).where(decidim_identities: { id: nil }).or(c.left_joins(:identities).where.not(decidim_identities: { id: spid_ids }))
              end
            end
            cie_filter = to_boolean(ransack_params.delete(:cie_presence))
            if !cie_filter.nil?
              if cie_filter
                c = c.left_joins(:identities).where(decidim_identities: { id: cie_ids })
              else
                c = c.left_joins(:identities).where(decidim_identities: { id: nil }).or(c.left_joins(:identities).where.not(decidim_identities: { id: cie_ids }))
              end
            end
            c
          end

          def search_field_predicate
            :name_or_nickname_or_email_cont
          end

          def filters
            [:officialized_at_null, :spid_presence, :cie_presence]
          end

          def to_boolean(str)
            return if str.nil?
            str == 'true'
          end

          def spid_ids
            Decidim::Identity.where(provider: Decidim::Spid.tenants.map(&:name)).pluck(:id)
          end

          def cie_ids
            Decidim::Identity.where(provider: Decidim::Cie.tenants.map(&:name)).pluck(:id)
          end
        end
      end
    end
  end
end