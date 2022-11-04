# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# frozen_string_literal: true

# Aggiunge al controller helper per i filtri

require_dependency Decidim::Admin::Engine.root.join('app', 'controllers', 'decidim', 'admin', 'logs_controller').to_s

module Decidim
  module Admin
    class LogsController < Decidim::Admin::ApplicationController
      include Decidim::Admin::Logs::Filterable

      helper_method :logs

      private

      def logs
        @logs ||= Decidim::ActionLog
                  .where(organization: current_organization)
                  .includes(:participatory_space, :user, :resource, :component, :version)
                  .for_admin

        if params[:q]
          if params[:q][:spid_operation] == 'true'
            identity_ids = Decidim::Identity.where(provider: Decidim::Spid.tenants.map(&:name))
            @logs = @logs.where(resource_type: "Decidim::Identity", resource_id: identity_ids)
          end
          if params[:q][:cie_operation] == 'true'
            identity_ids = Decidim::Identity.where(provider: Decidim::Cie.tenants.map(&:name))
            @logs = @logs.where(resource_type: "Decidim::Identity", resource_id: identity_ids)
          end
          if params[:q][:from].present?
            @logs = @logs.where("created_at >= ?", Date.parse(params[:q][:from]).at_beginning_of_day)
          end
          if params[:q][:to].present?
            @logs = @logs.where("created_at <= ?", Date.parse(params[:q][:to]).at_end_of_day)
          end
          @logs = @logs.where(action: params[:q][:action_type]) if params[:q][:action_type].present?
        end


        @logs = @logs.order(created_at: :desc)
                  .page(params[:page])
                  .per(params[:per_page])
      end

      def collection
        logs
      end

    end
  end
end
