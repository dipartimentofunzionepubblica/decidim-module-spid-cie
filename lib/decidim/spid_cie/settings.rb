require "onelogin/ruby-saml/settings"
require "onelogin/ruby-saml/attribute_service"

module Decidim
  module SpidCie
    #
    class Settings < ::OneLogin::RubySaml::Settings

      attr_accessor :errors

      def initialize(overrides = {}, keep_security_attributes = true)
        @errors = []
        if keep_security_attributes
          security_attributes = overrides.delete(:security) || security_config(overrides)
          config = DEFAULTS.merge(overrides)
          config[:security] = DEFAULTS[:security].merge(security_attributes)
        else
          config = DEFAULTS.merge(overrides)
        end

        config.each do |k,v|
          acc = "#{k}=".to_sym
          if !respond_to? acc
            singleton_class.class_eval { attr_accessor k }
          end
          value = v.is_a?(Hash) ? v.dup : v
          send(acc, value)
        end

        raise OmniAuth::Strategies::SAML::ValidationError.new(@errors.first) unless valid?
        default_service = ::OneLogin::RubySaml::AttributeService.new
        overrides.fields && overrides.fields.each do |field|
          default_service.add_attribute(field)
        end
        default_service.service_index(0)
        default_service.service_name(overrides.attribute_service_names[0] || "Set 0")
        @attribute_consuming_service = overrides.attribute_services.present? ? overrides.attribute_services : default_service
      end

      def valid?
        validate! && errors.blank?
      end

      protected

      def validate!
        errors << 'EntityID deve essere presente (impostare issuer)' if @issuer.blank?
        errors << 'Signature deve essere presente (impostare private_key)' if @private_key.blank?
        errors << 'Signature deve essere presente (impostare certificate)' if @certificate.blank?

        validate_signature_encryption
        validate_digest_encryption
        validate_key_size

        true
      end

      def validate_signature_encryption
        signature_algorithms = [
          XMLSecurity::Document::RSA_SHA1,
          XMLSecurity::Document::RSA_SHA256,
          XMLSecurity::Document::RSA_SHA384,
          XMLSecurity::Document::RSA_SHA512,
        ]
        if signature_algorithms.exclude?(@security.try(:[], :signature_method))
          errors << 'Signature deve essere presente (impostare encryption sha a 1, 256, 384, 512)'
        end
      end

      def validate_digest_encryption
        digest_algorithms =[
          XMLSecurity::Document::SHA1,
          XMLSecurity::Document::SHA256,
          XMLSecurity::Document::SHA384,
          XMLSecurity::Document::SHA512,
        ]
        if digest_algorithms.exclude?(@security.try(:[], :digest_method))
          errors << 'Signature deve essere presente (impostare encryption sha a 1, 256, 384, 512)'
        end
      end

      def validate_key_size
        return unless @private_key
        key = OpenSSL::PKey::RSA.new(@private_key)
        key_size = key.n.num_bytes * 8
        if key_size < 1024
          errors << 'Signature deve essere presente (impostare una chiave di almeno a 1024 bit'
        end
      end

      def security_config(ops)
        {
          metadata_signed: true,
          digest_method: digest_algorithm(ops[:sha]),
          signature_method: signature_algorithm(ops[:sha]),
          authn_requests_signed: true,
          want_assertions_signed: true,
          logout_requests_signed: true,
          check_sp_cert_expiration: false, # quando il certificato scade viene sollevata un eccezione
          strict_audience_validation: true
        }
      end

      def signature_algorithm(sha)
        case sha.to_s
        when '1'
          XMLSecurity::Document::RSA_SHA1
        when '256'
          XMLSecurity::Document::RSA_SHA256
        when '384'
          XMLSecurity::Document::RSA_SHA384
        when '512'
          XMLSecurity::Document::RSA_SHA512
        end
      end

      def digest_algorithm(sha)
        case sha.to_s
        when '1'
          XMLSecurity::Document::SHA1
        when '256'
          XMLSecurity::Document::SHA256
        when '384'
          XMLSecurity::Document::SHA384
        when '512'
          XMLSecurity::Document::SHA512
        end
      end

    end
  end
end