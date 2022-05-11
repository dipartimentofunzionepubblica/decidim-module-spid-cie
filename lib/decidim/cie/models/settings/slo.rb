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