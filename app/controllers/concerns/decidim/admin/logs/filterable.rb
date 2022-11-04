# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# frozen_string_literal: true

# Definizione filtri
require "active_support/concern"

module Decidim
  module Admin
    module Logs
      module Filterable
        extend ActiveSupport::Concern

        included do
          include Decidim::Admin::Filterable

          private

          def base_query
            collection
          end

          def filters
            [ :spid_presence, :cie_presence, :action_type]
          end

          def filters_with_values
            {
              spid_presence: %w(true false),
              cie_presence: %w(true false),
              action_type: %w(registration login logout),
            }
          end


        end
      end
    end
  end
end
