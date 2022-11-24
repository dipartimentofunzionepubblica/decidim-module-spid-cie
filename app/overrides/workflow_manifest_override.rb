# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Aggiunti instance method al model workflow
module Decidim
  module Verifications
    class WorkflowManifest

      def system_name
        I18n.t("#{key}.system_name", scope: "decidim.authorization_handlers", default: name.humanize).concat(name.match(/_identity/) ? " (tenant: #{name.gsub("_identity", "")})" : '')
      end

    end
  end
end