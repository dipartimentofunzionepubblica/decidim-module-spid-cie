# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Override per aggiungere e gestire i filtri SPID e CIE nel backoffice

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
            cie_filter = to_boolean(ransack_params.delete(:cie_presence))
            unless spid_filter.nil?
              c = spid_filter ? c.where(id: spid_ids) : c.where.not(id: spid_ids)
            end

            unless cie_filter.nil?
              c = cie_filter ? c.where(id: cie_ids) : c.where.not(id: cie_ids)
            end

            c.distinct
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
            Decidim::Identity.where(provider: Decidim::Spid.tenants.map(&:name)).pluck(:decidim_user_id)
          end

          def cie_ids
            Decidim::Identity.where(provider: Decidim::Cie.tenants.map(&:name)).pluck(:decidim_user_id)
          end
        end
      end
    end
  end
end