# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# frozen_string_literal: true

# Invia notifica email per informare l'utente che l'account è stato migrato
module Decidim
  module Spid
    class SpidMailer < Decidim::ApplicationMailer
      include Decidim::TranslationsHelper
      include Decidim::SanitizeHelper

      helper Decidim::TranslationsHelper

      def send_notification(user)
        with_user(user) do
          @user = user
          @organization = @user.organization

          subject = I18n.t(
            "subject",
            scope: "decidim.spid.spid_mailer"
          )
          mail(to: user.email, subject: subject)
        end
      end
    end
  end
end