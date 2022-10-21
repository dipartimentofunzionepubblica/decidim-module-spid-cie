require 'onelogin/ruby-saml'

# Necessario override della classe originaria della libreria,
# al fine di rendere conforme il nodo Issuer alle regole tecniche SPID,
# (aggiunte righe 32 e 33)

module OneLogin
  module RubySaml
    class Authrequest

      attr_accessor :issue_instant, :uuid

      def initialize
        @uuid = OneLogin::RubySaml::Utils.uuid
        time = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
        @issue_instant = time
      end

      def create_xml_document(settings)

        request_doc = XMLSecurity::Document.new
        request_doc.uuid = uuid

        root = request_doc.add_element 'samlp:AuthnRequest', { 'xmlns:samlp' => 'urn:oasis:names:tc:SAML:2.0:protocol', 'xmlns:saml' => 'urn:oasis:names:tc:SAML:2.0:assertion' }
        root.attributes['ID'] = uuid
        root.attributes['IssueInstant'] = @issue_instant
        root.attributes['Version'] = '2.0'
        # Cambiato idp_sso_service_url
        root.attributes['Destination'] = settings.idp_sso_service_url unless settings.idp_sso_service_url.nil?
        root.attributes['IsPassive'] = settings.passive unless settings.passive.nil?
        root.attributes['ProtocolBinding'] = settings.protocol_binding unless settings.protocol_binding.nil?
        # Aggiunto default value attributes_index
        root.attributes['AttributeConsumingServiceIndex'] = settings.current_consumer_index || settings.attributes_index || 0
        root.attributes['ForceAuthn'] = settings.force_authn unless settings.force_authn.nil?

        # Conditionally defined elements based on settings
        if settings.assertion_consumer_service_url != nil
          root.attributes['AssertionConsumerServiceURL'] = settings.assertion_consumer_service_url
        end

        if settings.consumer_services.present?
          root.attributes['AssertionConsumerServiceURL'] = settings.consumer_services[settings.current_consumer_index]['Location']
        end

        # NameQualifier e Format da requisiti SPID
        if settings.issuer != nil
          issuer = root.add_element 'saml:Issuer', {
            'NameQualifier' => settings.issuer,
            'Format' => 'urn:oasis:names:tc:SAML:2.0:nameid-format:entity'
          }
          issuer.text = settings.issuer
        end
        if settings.name_identifier_format != nil
          root.add_element 'samlp:NameIDPolicy', {
            # Might want to make AllowCreate a setting?
            # 'AllowCreate' => 'true', # Rimosso AllowCreate da requisiti SPID
            'Format' => settings.name_identifier_format
          }
        end

        if settings.authn_context || settings.authn_context_decl_ref

          if settings.authn_context_comparison != nil
            comparison = settings.authn_context_comparison
          else
            comparison = 'exact'
          end

          requested_context = root.add_element 'samlp:RequestedAuthnContext', {
            'Comparison' => comparison,
          }

          if settings.authn_context != nil
            authn_contexts_class_ref = settings.authn_context.is_a?(Array) ? settings.authn_context : [settings.authn_context]
            authn_contexts_class_ref.each do |authn_context_class_ref|
              class_ref = requested_context.add_element 'saml:AuthnContextClassRef'
              class_ref.text = authn_context_class_ref
            end
          end

          if settings.authn_context_decl_ref != nil
            authn_contexts_decl_refs = settings.authn_context_decl_ref.is_a?(Array) ? settings.authn_context_decl_ref : [settings.authn_context_decl_ref]
            authn_contexts_decl_refs.each do |authn_context_decl_ref|
              decl_ref = requested_context.add_element 'saml:AuthnContextDeclRef'
              decl_ref.text = authn_context_decl_ref
            end
          end
        end

        request_doc
      end

    end
  end
end
