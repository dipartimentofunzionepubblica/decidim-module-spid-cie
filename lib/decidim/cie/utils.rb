module Decidim
  module Cie
    module Utils

      cattr_accessor :current_name, default: ''

      def metadata_xml(overrides = {})
        metadata = Decidim::Cie::Metadata.new
        metadata.to_xml(Decidim::Cie::Settings::Metadata.new(overrides))
      end

      def sso_saml(sso_params, options)
        request = Decidim::Cie::SsoRequest.new(sso_params, options)
        session[:"#{session_prefix}sso_params"] = sso_params
        request.to_saml
      end

      def slo_saml(slo_params, options)
        logout_request = Decidim::Cie::SloRequest.new(slo_params, options)
        session[:"#{session_prefix}slo_id"] = logout_request.uuid
        logout_request.to_saml
      end

      def sso_request(saml_response, options)
        r = Decidim::Cie::SsoResponse.new(saml_response, session[:"#{session_prefix}sso_params"], options)
        response = r.response
        valid = r.valid?
        if valid
          session[:"#{session_prefix}uid"] = response.attributes[options.uid_attribute] || response.name_id.try(:strip)
          session[:"#{session_prefix}index"] = r.session_index
          session[:"#{session_prefix}login_time"] = Time.now
          msg = I18n.t('cie.sso_request.success')
        else
          msg = I18n.t('cie.sso_request.failure')
        end
        [valid, msg, response]
      end

      def slo_request(saml_response, options)
        response = Decidim::Cie::SloResponse.new(saml_response, session[:"#{session_prefix}sso_params"].merge(slo_id: session[:"#{session_prefix}slo_id"]), options)
        valid = response.valid?
        if valid
          session.delete(:"#{session_prefix}sso_params")
          session.delete(:"#{session_prefix}index")
          session.delete(:"#{session_prefix}slo_id")
          session.delete(:"#{session_prefix}relay_state")
          session.delete(:"#{session_prefix}login_time")
          msg = I18n.t('decidim.cie.slo_request.success')
        else
          msg = I18n.t('decidim.cie.slo_request.failure')
        end
        [valid, msg]
      end

      def slo_params
        sso_params = {}
        sso_params[:sso] = { idp: session[:"#{session_prefix}sso_params"].dig("sso", "idp") }
        sso_params[:cie_level] = session[:"#{session_prefix}sso_params"]["cie_level"]
        sso_params[:session_index] = session[:"#{session_prefix}index"]
        sso_params[:relay_state] = Base64.strict_decode64(session[:"#{session_prefix}sso_params"]["relay_state"])
        sso_params
      end

      def session_prefix
        self.current_name + '_cie_'
      end

      def self.session_prefix
        current_name + '_cie_'
      end

    end
  end
end