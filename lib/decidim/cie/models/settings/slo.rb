# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Settings per logout SAML
module Decidim
  module Cie
    module Settings
      class Slo < Base

        def initialize(cie_params)
          super

          slo_attributes = settings.merge(idp_attributes)
          slo_attributes[:sessionindex] = @session_index
          slo_attributes[:relay_state] = relay_state
          slo_attributes[:protocol_binding] = self.class.saml_bindings[:post]
          @settings = slo_attributes
        end

        protected

        def validate!
          #todo: implement validation response
          true
        end

      end
    end
  end
end