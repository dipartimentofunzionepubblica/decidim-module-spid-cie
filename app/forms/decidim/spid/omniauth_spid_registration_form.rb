# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

module Decidim
  module Spid
    class OmniauthSpidRegistrationForm < ::Decidim::OmniauthRegistrationForm

      validates :nickname, presence: true

      def normalized_nickname
        nickname
      end

      def raw_data
        super.to_json
      end

    end
  end
end