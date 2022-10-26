# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

require "active_support/configurable"
require "action_controller"

module Decidim
  module Spid
    class TokenVerifier
      include ActiveSupport::Configurable
      include ActionController::RequestForgeryProtection

      config.each_key do |configuration_name|
        undef_method configuration_name
        define_method configuration_name do
          ActionController::Base.config[configuration_name]
        end
      end

      def call(env)
        @request = ActionDispatch::Request.new(env.dup)

        unless verified_request?
          raise ActionController::InvalidAuthenticityToken
        end
      end

      private

      attr_reader :request
      delegate :params, :session, to: :request
    end
  end
end