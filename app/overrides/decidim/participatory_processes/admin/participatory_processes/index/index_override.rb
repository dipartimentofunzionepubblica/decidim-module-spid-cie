# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

Deface::Override.new(virtual_path: "decidim/participatory_processes/admin/participatory_processes/index",
                     name: "add-custom-export",
                     insert_top: "td.table-list__actions") do
  '
  <% if allowed_to? :create, :process, process: process %>
    <%= icon_link_to "data-transfer-download", decidim_spid_admin.exports_path(slug: process), t("actions.export", scope: "decidim.spid.admin"), class: "action-icon--export" %>
  <% else %>
    <span class="action-space icon"></span>
  <% end %>
'
end