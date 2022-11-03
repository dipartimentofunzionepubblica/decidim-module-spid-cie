# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# frozen_string_literal: true

# ridefinizione del create_or_find_user per aggiungere la notifica email
module Decidim
  module Cie
    class CreateOmniauthCieRegistration < ::Decidim::CreateOmniauthRegistration

      private

      def create_or_find_user
        generated_password = SecureRandom.hex

        @user = User.find_or_initialize_by(
          email: verified_email,
          organization: organization
        )

        if persisted = @user.persisted?
          @user.skip_confirmation! if !@user.confirmed? && @user.email == verified_email
          @user.nickname = form.normalized_nickname if form.invitation_token.present?
        else
          @user.email = (verified_email || form.email)
          @user.name = form.name
          @user.nickname = form.normalized_nickname
          @user.newsletter_notifications_at = nil
          @user.email_on_notification = true
          @user.password = generated_password
          @user.password_confirmation = generated_password
          if form.avatar_url.present?
            url = URI.parse(form.avatar_url)
            filename = File.basename(url.path)
            file = URI.open(url)
            @user.avatar.attach(io: file, filename: filename)
          end
          @user.skip_confirmation! if verified_email
        end

        @user.tos_agreement = "1"
        @user.save! && persisted && Decidim::Cie::CieJob.perform_later(@user)
      end

    end

  end
end
