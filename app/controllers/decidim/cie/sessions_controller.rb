# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# frozen_string_literal: true

# Gestisce il logout CIE, SPID o standard
module Decidim
  module Cie
    class SessionsController < ::Decidim::Devise::SessionsController

      include Decidim::Cie::Utils

      def destroy
        if session.delete("decidim-cie.signed_in")
          i = current_user.identities.find_by(uid: session["#{Decidim::Cie::Utils.session_prefix}uid"]) rescue nil
          Decidim::ActionLogger.log(:logout, current_user, i, {}) if i
          redirect_to decidim_cie.public_send("user_#{current_organization.enabled_omniauth_providers.dig(:cie, :tenant_name)}_omniauth_spslo_url")
        elsif session.delete("decidim-spid.signed_in")
          i = current_user.identities.find_by(uid: session["#{Decidim::Spid::Utils.session_prefix}uid"]) rescue nil
          Decidim::ActionLogger.log(:logout, current_user, i, {}) if i
          redirect_to decidim_spid.public_send("user_#{current_organization.enabled_omniauth_providers.dig(:spid, :tenant_name)}_omniauth_spslo_url")
        else
          super
        end
      end

      def slo_callback
        set_flash_message! :notice, :signed_out if params[:success] == "true"
        current_user.invalidate_all_sessions!
        return redirect_to(decidim.new_user_session_path) if current_organization.force_users_to_authenticate_before_access_organization

        redirect_to params[:path] || decidim.root_path
      end
    end
  end
end
