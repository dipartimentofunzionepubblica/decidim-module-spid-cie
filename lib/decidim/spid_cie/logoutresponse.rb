# Only supports SAML 2.0
module Decidim
  module SpidCie

    # SAML2 Logout Response (SLO IdP initiated, Parser)
    #
    class Logoutresponse < ::OneLogin::RubySaml::Logoutresponse

      def issuer
        @issuer ||= begin
                      node = REXML::XPath.first(
                        document,
                        "/p:LogoutResponse/a:Issuer",
                        { "p" => PROTOCOL, "a" => ASSERTION }
                      )
                      ::OneLogin::RubySaml::Utils.element_text(node).try(:strip) # Demo validator send "\n    ......"
                    end
      end

    end
  end
end
