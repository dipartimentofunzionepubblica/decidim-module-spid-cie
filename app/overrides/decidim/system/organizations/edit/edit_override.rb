# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Aggiunge il tenant name all'autorizzazione
Deface::Override.new(virtual_path: "decidim/system/organizations/edit",
                     name: "add-tenant-name",
                     replace: "erb:contains('f.collection_check_boxes :available_authorizations, Decidim.authorization_workflows, :name, :description')") do
  '
  <%= f.collection_check_boxes :available_authorizations, Decidim.authorization_workflows, :name, :system_name %>
  '
end