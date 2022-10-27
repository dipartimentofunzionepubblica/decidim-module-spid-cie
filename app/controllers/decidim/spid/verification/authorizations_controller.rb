# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# frozen_string_literal: true

# Aggiunge la possibilità di collegare l'account CIE dalle impostazioni
# dell'utente se le autorizzazioni sono abilitate da /system
module Decidim
  module Spid
    module Verification
      class AuthorizationsController < ::Decidim::Verifications::ApplicationController
        skip_before_action :store_current_location

        helper_method :handler, :unauthorized_methods, :authorization_method, :authorization

        # todo: remove unnecessary
        include Decidim::UserProfile
        # include Decidim::Verifications::Renewable
        helper Decidim::DecidimFormHelper
        helper Decidim::CtaButtonHelper
        helper Decidim::AuthorizationFormHelper
        helper Decidim::TranslationsHelper

        layout "layouts/decidim/user_profile", only: [:new]

        def new
          render :new
        end
      end
    end
  end
end