# frozen_string_literal: true

module Decidim
  module Spid
    class SessionsController < ::Decidim::Devise::SessionsController

      include Decidim::Spid::Utils

      def destroy
        if session.delete("decidim-spid.signed_in")
          redirect_to decidim_spid.public_send("user_#{current_organization.enabled_omniauth_providers.dig(:spid, :tenant_name)}_omniauth_spslo_url")
        else
          super
        end
      end

      def slo_callback
        set_flash_message! :notice, :signed_out if params[:success] == "true"
        current_user.invalidate_all_sessions!
        # Redirect to the root path when the organization forces users to
        # authenticate before accessing the organization.
        return redirect_to(decidim.new_user_session_path) if current_organization.force_users_to_authenticate_before_access_organization

        redirect_to params[:path] || decidim.root_path
      end
    end
  end
end
