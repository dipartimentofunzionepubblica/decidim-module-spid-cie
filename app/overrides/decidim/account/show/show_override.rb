# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Una volta loggato con SPID viene disabilitata la possibiltò di cambiare password
Deface::Override.new(virtual_path: "decidim/account/show",
                     name: "remove-change-password-with-spid",
                     replace: "erb[silent]:contains('if current_organization.sign_in_enabled?')",
                     closing_selector: "erb[silent]:contains('end')" ) do
"
  <% if current_organization.sign_in_enabled? && !current_user.must_log_with_spid? %>
    <p>
      <a data-toggle='passwordChange' class='change-password'><%= t '.change_password' %></a>
    </p>
    <div id='passwordChange' class='toggle-show' data-toggler='.is-expanded'>
      <%= render partial: 'password_fields', locals: { form: f } %>
    </div>
  <% end %>
"
end

Deface::Override.new(virtual_path: "decidim/account/show",
                     name: "disable-email-when-is-a-spid-account",
                     replace: "erb:contains('f.email_field :email')") do
  "
  <%= f.email_field :email, readonly: session['decidim-spid.tenant'].present? %>
  "
end