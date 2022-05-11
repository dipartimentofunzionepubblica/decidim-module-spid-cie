module Decidim
  module Cie
    module Settings
      class Base
        attr_accessor :errors
        attr_accessor :settings

        def initialize cie_params
          @bindings = [:redirect, :post]
          @errors = []
          cie_params && cie_params.each do |k, v|
            singleton_class.class_eval { attr_accessor k }
            send("#{k}=", v)
          end
          @settings = sp_attributes
        end

        def security_attributes
          dig_alg = Certificate.digest_algorithm(@sha)
          sig_alg = Certificate.signature_algorithm(@sha)
          {
            metadata_signed: true,
            digest_method: dig_alg,
            signature_method: sig_alg,
            authn_requests_signed: true,
            want_assertions_signed: true,
            logout_requests_signed: true,
            check_sp_cert_expiration: false # quando il certificato scade viene sollevata un eccezione
          }
        end

        def sp_attributes
          {
            issuer: @issuer,
            assertion_consumer_service_url: @assertion_consumer_service_url,
            single_logout_service_url: @single_logout_service_url,
            private_key: @private_key || (private_key_path && File.exists?(private_key_path) ? File.read("#{private_key_path}") : nil),
            certificate: @certificate || (certificate_path && File.exists?(certificate_path) ? File.read("#{certificate_path}") : nil),
            security: security_attributes
          }
        end

        def idp_attributes
          idp = Cie::Idp.find(@idp.to_s)
          bindings = @bindings.map { |verb| self.class.saml_bindings[verb] }
          parser = OneLogin::RubySaml::IdpMetadataParser.new
          parser.parse_remote_to_hash(idp.metadata_url, idp.validate_cert?, sso_binding: bindings, slo_binding: bindings)
        end

        def valid?
          validate! && errors.blank?
        end

        protected

        def validate!
          errors << "Validation not implemented yet"
        end

        def authn_context
          "https://www.spid.gov.it/SpidL#{@cie_level}"
        end

        def force_authn
          return true if @cie_level != 1
        end

        def self.saml_bindings
          {
            post: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
            redirect: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'
          }
        end

      end
    end

  end
end