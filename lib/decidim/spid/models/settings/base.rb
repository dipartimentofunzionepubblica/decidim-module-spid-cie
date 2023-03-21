# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Classe di configurazione setting per SP provider & Idp Provider
module Decidim
  module Spid
    module Settings
      class Base
        attr_accessor :errors
        attr_accessor :settings

        def initialize spid_params
          @bindings = [:redirect, :post]
          @errors = []
          spid_params && spid_params.each do |k, v|
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
            check_sp_cert_expiration: false, # quando il certificato scade viene sollevata un eccezione
            strict_audience_validation: true
          }
        end

        def sp_attributes
          {
            issuer: @issuer,
            assertion_consumer_service_url: @assertion_consumer_service_url,
            single_logout_service_url: @single_logout_service_url,
            consumer_services: @consumer_services,
            logout_services: @logout_services,
            private_key: @private_key || (private_key_path && File.exists?(private_key_path) ? File.read("#{private_key_path}") : nil),
            certificate: @certificate || (certificate_path && File.exists?(certificate_path) ? File.read("#{certificate_path}") : nil),
            security: security_attributes,
            attribute_consuming_service: @attribute_services.present? ? @attribute_services : nil,
            attribute_service_names: @attribute_service_names,
            default_service_index: @default_service_index,
            current_consumer_index: @current_consumer_index,
            current_attribute_index: @current_attribute_index,
            current_logout_index: @current_logout_index,
            name_identifier_value: @name_identifier_value,
            idp_name_qualifier: @idp_name_qualifier,
            name_identifier_format: @name_identifier_format
          }
        end

        def idp_attributes
          idp = Spid::Idp.find(@idp.to_s)
          bindings = @bindings.map { |verb| self.class.saml_bindings[verb] }
          parser = OneLogin::RubySaml::IdpMetadataParser.new
          parser.parse_remote_to_hash(idp.metadata_url, idp.validate_cert?)
        end

        def valid?
          validate! && errors.blank?
        end

        protected

        def validate!
          errors << "Validation not implemented yet"
        end

        def authn_context
          "https://www.spid.gov.it/SpidL#{@spid_level}"
        end

        def force_authn
          return true if @spid_level != 1
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