# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Creata form custom per forzare l'utente a scegliere il nickname
module Decidim
  module Cie
    class OmniauthCieRegistrationForm < ::Decidim::OmniauthRegistrationForm

      attribute :invitation_token, String

      validates :nickname, presence: true

      def normalized_nickname
        nickname
      end

      def raw_data
        data = super
        data.is_a?(Hash) ? data.to_json : data
      end

    end
  end
end