# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Aggiunti instance method al model utente
module Decidim
  class User

    def must_log_with_spid?
      identities.map(&:provider).include?(organization.enabled_omniauth_providers.dig(:spid, :tenant_name))
    end

    def must_log_with_cie?
      identities.map(&:provider).include?(organization.enabled_omniauth_providers.dig(:cie, :tenant_name))
    end

    # per disabilatare il recupera password se in precedenza hai fatto l'accesso con SPID
    def send_reset_password_instructions
      errors.add(:email, :cant_recover_password_due_spid) unless !self.must_log_with_spid?
      super
    end

    def self.find_for_authentication(warden_conditions)
      organization = warden_conditions.dig(:env, "decidim.current_organization")
      user = find_by(
        email: warden_conditions[:email].to_s.downcase,
        decidim_organization_id: organization.id
      )
      return nil if user.is_a?(Decidim::User) && user.must_log_with_spid?
      user
    end
  end
end