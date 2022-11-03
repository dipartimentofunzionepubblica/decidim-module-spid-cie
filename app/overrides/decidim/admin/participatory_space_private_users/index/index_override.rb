# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Aggiunge badge SPID o CIE agli utenti nel backoffice che hanno utilizzato
# queste autorizzazioni
Deface::Override.new(virtual_path: "decidim/admin/participatory_space_private_users/index",
                     name: "add-badge-spid-header-to-private-users",
                     insert_before: 'div.card-section thead tr th.actions') do
  '
  <th><%= t("decidim.admin.officializations.index.badge") %></th>
'
end

Deface::Override.new(virtual_path: "decidim/admin/participatory_space_private_users/index",
                     name: "add-badge-spid-to-private-users",
                     insert_before: 'div.card-section tbody tr td.table-list__actions') do
  '
  <td><%= private_user.user.must_log_with_spid? ? spid_icon : "" %>
  <%= private_user.user.must_log_with_cie? ? cie_icon : "" %></td>
'
end