# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# frozen_string_literal: true

module Decidim
  module Spid
    module AdminLog
      class IdentityPresenter < Decidim::Log::BasePresenter
        private

        def action_string
          case action
          when "registration", "login", "logout"
            "decidim.admin_log.identity.#{action}"
          else
            super
          end
        end

        def i18n_labels_scope
          "activemodel.attributes.identity"
        end

        def i18n_params
          {
            user_name: user_presenter.present,
            resource_name: resource_presenter.try(:present),
            space_name: space_presenter.try(:present) || "",
            timestamp_utc: action_log.extra.try(:[], "timestamp_utc") || action_log.extra.try(:dig, "extra", "timestamp_utc") || "",
            saml_transaction_id: action_log.extra.try(:[], "saml_transaction_id") || action_log.extra.try(:dig, "extra", "saml_transaction_id") || ""
          }
        end

        def resource_presenter
          @resource_presenter ||= Decidim::Spid::IdentityPresenter.new(action_log.resource, h, action_log.extra.try(:[], "resource") || {})
        end

        def space_presenter
          nil
        end
      end
    end
  end
end