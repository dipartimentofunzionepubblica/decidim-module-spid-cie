# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Agginge filtri di ricerca per i log
Deface::Override.new(virtual_path: "decidim/admin/logs/_logs_list",
                     name: "add-log_filters",
                     insert_before: "ul.logs.table", original: '3780c8d6d0b33ef1d66e7efadb0d92a7e6d498ff' ) do
  '
  <%= render partial: "decidim/admin/shared/identity_filters", locals: { i18n_ctx: nil } %>
  '
end

Deface::Override.new(virtual_path: "decidim/admin/logs/_logs_list",
                     name: "add-log_filters-no-results",
                     insert_before: "div.logs.table", original: '3780c8d6d0b33ef1d66e7efadb0d92a7e6d498ff' ) do
  '
  <%= render partial: "decidim/admin/shared/identity_filters", locals: { i18n_ctx: nil } %>
  '
end