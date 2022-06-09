Deface::Override.new(virtual_path: "decidim/admin/officializations/index",
                     name: "add-badge-spid",
                     insert_before: 'div.card-section tbody tr td erb[loud]:contains("user.officialized?")') do
'
  <%= user.must_log_with_spid? ? spid_icon : "" %>
  <%= user.must_log_with_cie? ? cie_icon : "" %>
'
end