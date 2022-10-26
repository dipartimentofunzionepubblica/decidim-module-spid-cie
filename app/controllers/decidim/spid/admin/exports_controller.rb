# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# frozen_string_literal: true

module Decidim
  module Spid
    module Admin
      class ExportsController < Decidim::Spid::Admin::ApplicationController

        include Decidim::Admin::ParticipatorySpaceAdminContext
        include Decidim::ParticipatoryProcesses::Admin::Filterable
        include Decidim::ParticipatoryProcesses::Admin::Concerns::ParticipatoryProcessAdmin

        helper Decidim::ParticipatoryProcesses::Admin::ProcessGroupsForSelectHelper
        helper Decidim::ParticipatoryProcesses::Admin::ParticipatoryProcessHelper

        helper_method :current_participatory_process, :current_participatory_space, :process_group

        layout "decidim/admin/participatory_processes"

        def index
          enforce_permission_to :create, :process, process: current_participatory_process
          UserExportJob.perform_now(current_user, current_participatory_process, 'decidim_spid_users', 'CSV')
          flash[:notice] = t("decidim.admin.exports.notice")
          redirect_back(fallback_location: decidim_admin_participatory_processes.participatory_processes_path)
        end

        private

        def collection
          @collection ||= ParticipatoryProcessesWithUserRole.for(current_user)
        end

        def current_participatory_process
          @current_participatory_process ||= collection.where(slug: params[:slug]).or(
            collection.where(id: params[:slug])
          ).first
        end
        alias current_participatory_space current_participatory_process

        def permission_class_chain
          [::Decidim::ParticipatoryProcesses::Permissions,
           ::Decidim::Admin::Permissions]
        end

      end
    end
  end
end