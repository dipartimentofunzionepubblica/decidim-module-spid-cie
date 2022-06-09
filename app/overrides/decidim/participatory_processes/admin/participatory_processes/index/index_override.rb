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