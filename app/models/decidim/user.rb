require_dependency Decidim::Core::Engine.root.join('app', 'models', 'decidim', 'user').to_s

module Decidim
  class User

    def must_log_with_spid?
      identities.map(&:provider).include?(organization.enabled_omniauth_providers.dig(:spid, :tenant_name))
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