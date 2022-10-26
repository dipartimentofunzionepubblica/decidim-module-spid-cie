# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

module Decidim
  module Spid
    module Settings

      class Sso < Base

        def initialize(spid_params)
          super

          sso_attributes = settings.merge(idp_attributes)
          sso_attributes[:authn_context] = authn_context
          sso_attributes[:authn_context_comparison] = 'minimum'
          sso_attributes[:force_authn] = force_authn
          sso_attributes[:protocol_binding] = self.class.superclass.saml_bindings[:post]
          sso_attributes[:relay_state] = relay_state
          sso_attributes[:current_consumer_index] = settings[:current_consumer_index]
          sso_attributes[:current_attribute_index] = settings[:current_attribute_index]
          @settings = sso_attributes
        end

        protected

        def validate!
          if settings[:idp_sso_service_url].blank?
            errors << 'Destination deve essere presente (impostare idp_sso_service_url)'
          end
          if settings[:authn_context].last != '1' && settings[:force_authn] != true
            errors << 'ForceAuthn deve essere presente per livelli di autenticazione diversi da SPIDL1 (impostare force_authn a true)'
          end
          if settings[:authn_context_comparison] != 'minimum'
            errors << "AuthnContextComparison deve essere settato a 'minimum' (impostare authn_context_comparison a 'minimum')"
          end

          true
        end

        private

        def self.saml_bindings
          {
            redirect: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'
          }
        end

      end

    end
  end
end