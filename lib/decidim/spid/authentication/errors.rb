# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# frozen_string_literal: true

module Decidim
  module Spid
    module Authentication
      class Error < StandardError; end

      class AuthorizationBoundToOtherUserError < Error; end
      class IdentityBoundToOtherUserError < Error; end

      class ValidationError < Error
        attr_reader :validation_key

        def initialize(msg = nil, validation_key = :invalid_data)
          @validation_key = validation_key
          super(msg)
        end
      end
    end
  end
end