Deface::Override.new(virtual_path: "decidim/system/organizations/_omniauth_provider",
                     name: "add-certificate-expiration",
                     insert_bottom: "div.card-section") do
  '
  <% if provider == :spid && (tenant = Decidim::Spid.tenants.find { |t| t.name == f.object.try(:omniauth_settings_spid_tenant_name) } ) %>
    <% if tenant.certificate.present? && (c = OpenSSL::X509::Certificate.new(tenant.certificate) rescue nil)  %>
        <p class="help-text"><%= t("certificate", scope: "#{i18n_scope}.#{provider}", date: c.not_after) %></p>
    <% end %>
    <% if tenant.new_certificate.present? && (nc = OpenSSL::X509::Certificate.new(tenant.new_certificate) rescue nil)  %>
      <p class="help-text"><%= t("new_certificate", scope: "#{i18n_scope}.#{provider}", date: nc.not_after) %></p>
    <% end %>
  <% end %>

  <% if provider == :cie && (tenant = Decidim::Cie.tenants.find { |t| t.name == f.object.try(:omniauth_settings_cie_tenant_name) } ) %>
    <% if tenant.certificate.present? && (c = OpenSSL::X509::Certificate.new(tenant.certificate) rescue nil)  %>
      <p class="help-text"><%= t("certificate", scope: "#{i18n_scope}.#{provider}", date: c.not_after) %></p>
    <% end %>
    <% if tenant.new_certificate.present? && (nc = OpenSSL::X509::Certificate.new(tenant.new_certificate) rescue nil)  %>
      <p class="help-text"><%= t("new_certificate", scope: "#{i18n_scope}.#{provider}", date: nc.not_after) %></p>
    <% end %>
  <% end %>
'
end