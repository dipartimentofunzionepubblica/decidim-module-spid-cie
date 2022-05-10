require "active_support/concern"

module Decidim
  module Admin
    module Officializations
      module FilterableOverrides
        extend ActiveSupport::Concern

        included do
          include Decidim::Admin::Filterable

          helper Decidim::LayoutHelper
          helper Decidim::Spid::Admin::SpidHelper

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
            c
          end

          def search_field_predicate
            :name_or_nickname_or_email_cont
          end

          def filters
            [:officialized_at_null, :spid_presence]
          end

          def to_boolean(str)
            return if str.nil?
            str == 'true'
          end

          def spid_ids
            Decidim::Identity.where(provider: Decidim::Spid.tenants.map(&:name)).pluck(:id)
          end
        end
      end
    end
  end
end
