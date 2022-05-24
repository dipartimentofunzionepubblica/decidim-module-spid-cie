# frozen_string_literal: true

require 'utils/certificate_generator'
require "spec_helper"
require "omniauth/strategies/spid_saml"

RSpec::Matchers.define :fail_with do |message|
  match do |actual|
    actual.redirect? && actual.location == /\?.*message=#{message}/
  end
end

# Silence the OmniAuth logger
# OmniAuth.config.logger = Logger.new("/dev/null")

module OmniAuth
  module Strategies
    describe SpidSaml, type: :strategy do
      include Rack::Test::Methods
      include OmniAuth::Test::StrategyTestCase

      def base64_file(filename)
        Base64.strict_encode64(IO.read(file_fixture(filename)))
      end

      let(:certgen) { OmniAuth::Spid::Test::CertificateGenerator.new }
      let(:private_key) { certgen.private_key }
      let(:certificate) { certgen.certificate }

      let(:tenant) { Decidim::Spid.tenants.first }
      let(:auth_hash) { last_request.env["omniauth.auth"] }
      let(:idp_attributes) {
        {
          idp_entity_id: "https://localhost:8443/demo",
          name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:transient",
          idp_sso_service_url: "https://localhost:8443/demo/samlsso",
          idp_sso_service_binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
          idp_slo_service_url: "https://localhost:8443/demo/samlsso",
          idp_slo_service_binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
          idp_slo_response_service_url: "https://localhost:8443/demo/samlsso",
          idp_attribute_names: [],
          idp_cert: "MIIEGDCCAwCgAwIBAgIJAOrYj9oLEJCwMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAklUMQ4wDAYDVQQIEwVJdGFseTENMAsGA1UEBxMEUm9tZTENMAsGA1UEChMEQWdJRDESMBAGA1UECxMJQWdJRCBURVNUMRQwEgYDVQQDEwthZ2lkLmdvdi5pdDAeFw0xOTA0MTExMDAyMDhaFw0yNTAzMDgxMDAyMDhaMGUxCzAJBgNVBAYTAklUMQ4wDAYDVQQIEwVJdGFseTENMAsGA1UEBxMEUm9tZTENMAsGA1UEChMEQWdJRDESMBAGA1UECxMJQWdJRCBURVNUMRQwEgYDVQQDEwthZ2lkLmdvdi5pdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK8kJVo+ugRrbbv9xhXCuVrqi4B7/MQzQc62ocwlFFujJNd4m1mXkUHFbgvwhRkQqo2DAmFeHiwCkJT3K1eeXIFhNFFroEzGPzONyekLpjNvmYIs1CFvirGOj0bkEiGaKEs+/umzGjxIhy5JQlqXE96y1+Izp2QhJimDK0/KNij8I1bzxseP0Ygc4SFveKS+7QO+PrLzWklEWGMs4DM5Zc3VRK7g4LWPWZhKdImC1rnS+/lEmHSvHisdVp/DJtbSrZwSYTRvTTz5IZDSq4kAzrDfpj16h7b3t3nFGc8UoY2Ro4tRZ3ahJ2r3b79yK6C5phY7CAANuW3gDdhVjiBNYs0CAwEAAaOByjCBxzAdBgNVHQ4EFgQU3/7kV2tbdFtphbSA4LH7+w8SkcwwgZcGA1UdIwSBjzCBjIAU3/7kV2tbdFtphbSA4LH7+w8SkcyhaaRnMGUxCzAJBgNVBAYTAklUMQ4wDAYDVQQIEwVJdGFseTENMAsGA1UEBxMEUm9tZTENMAsGA1UEChMEQWdJRDESMBAGA1UECxMJQWdJRCBURVNUMRQwEgYDVQQDEwthZ2lkLmdvdi5pdIIJAOrYj9oLEJCwMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAJNFqXg/V3aimJKUmUaqmQEEoSc3qvXFITvT5f5bKw9yk/NVhR6wndL+z/24h1OdRqs76blgH8k116qWNkkDtt0AlSjQOx5qvFYh1UviOjNdRI4WkYONSw+vuavcx+fB6O5JDHNmMhMySKTnmRqTkyhjrch7zaFIWUSV7hsBuxpqmrWDoLWdXbV3eFH3mINA5AoIY/m0bZtzZ7YNgiFWzxQgekpxd0vcTseMnCcXnsAlctdir0FoCZztxMuZjlBjwLTtM6Ry3/48LMM8Z+lw7NMciKLLTGQyU8XmKKSSOh0dGh5Lrlt5GxIIJkH81C0YimWebz8464QPL3RbLnTKg+c=", :idp_cert_fingerprint=>"EF:DE:F0:ED:5D:55:7A:3D:0D:4B:BD:5D:C9:3C:EE:07:DF:F9:5F:CB",
          idp_cert_multi: {
            signing:
              ["MIIEGDCCAwCgAwIBAgIJAOrYj9oLEJCwMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAklUMQ4wDAYDVQQIEwVJdGFseTENMAsGA1UEBxMEUm9tZTENMAsGA1UEChMEQWdJRDESMBAGA1UECxMJQWdJRCBURVNUMRQwEgYDVQQDEwthZ2lkLmdvdi5pdDAeFw0xOTA0MTExMDAyMDhaFw0yNTAzMDgxMDAyMDhaMGUxCzAJBgNVBAYTAklUMQ4wDAYDVQQIEwVJdGFseTENMAsGA1UEBxMEUm9tZTENMAsGA1UEChMEQWdJRDESMBAGA1UECxMJQWdJRCBURVNUMRQwEgYDVQQDEwthZ2lkLmdvdi5pdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK8kJVo+ugRrbbv9xhXCuVrqi4B7/MQzQc62ocwlFFujJNd4m1mXkUHFbgvwhRkQqo2DAmFeHiwCkJT3K1eeXIFhNFFroEzGPzONyekLpjNvmYIs1CFvirGOj0bkEiGaKEs+/umzGjxIhy5JQlqXE96y1+Izp2QhJimDK0/KNij8I1bzxseP0Ygc4SFveKS+7QO+PrLzWklEWGMs4DM5Zc3VRK7g4LWPWZhKdImC1rnS+/lEmHSvHisdVp/DJtbSrZwSYTRvTTz5IZDSq4kAzrDfpj16h7b3t3nFGc8UoY2Ro4tRZ3ahJ2r3b79yK6C5phY7CAANuW3gDdhVjiBNYs0CAwEAAaOByjCBxzAdBgNVHQ4EFgQU3/7kV2tbdFtphbSA4LH7+w8SkcwwgZcGA1UdIwSBjzCBjIAU3/7kV2tbdFtphbSA4LH7+w8SkcyhaaRnMGUxCzAJBgNVBAYTAklUMQ4wDAYDVQQIEwVJdGFseTENMAsGA1UEBxMEUm9tZTENMAsGA1UEChMEQWdJRDESMBAGA1UECxMJQWdJRCBURVNUMRQwEgYDVQQDEwthZ2lkLmdvdi5pdIIJAOrYj9oLEJCwMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAJNFqXg/V3aimJKUmUaqmQEEoSc3qvXFITvT5f5bKw9yk/NVhR6wndL+z/24h1OdRqs76blgH8k116qWNkkDtt0AlSjQOx5qvFYh1UviOjNdRI4WkYONSw+vuavcx+fB6O5JDHNmMhMySKTnmRqTkyhjrch7zaFIWUSV7hsBuxpqmrWDoLWdXbV3eFH3mINA5AoIY/m0bZtzZ7YNgiFWzxQgekpxd0vcTseMnCcXnsAlctdir0FoCZztxMuZjlBjwLTtM6Ry3/48LMM8Z+lw7NMciKLLTGQyU8XmKKSSOh0dGh5Lrlt5GxIIJkH81C0YimWebz8464QPL3RbLnTKg+c="]
          }
        }
      }
      let(:saml_options) do
        {
          name: tenant.config[:name],
          sp_entity_id: sp_entity_id,
          certificate: certificate.to_pem,
          private_key: private_key.to_pem,
          security: security_options,
          issuer: sp_entity_id,
          sp_name_qualifier: tenant.omniauth_settings[:sp_name_qualifier],
          assertion_consumer_service_url: tenant.omniauth_settings[:assertion_consumer_service_url],
          single_logout_service_url: tenant.omniauth_settings[:single_logout_service_url],
          # private_key: @private_key || (private_key_path && File.exists?(private_key_path) ? File.read("#{private_key_path}") : nil),
          # certificate: @certificate || (certificate_path && File.exists?(certificate_path) ? File.read("#{certificate_path}") : nil),
        }.merge(idp_attributes)
      end

      let(:security_options) {
        dig_alg = Decidim::Spid::Certificate.digest_algorithm(tenant.config[:sha])
        sig_alg = Decidim::Spid::Certificate.signature_algorithm(tenant.config[:sha])
        {
          metadata_signed: true,
          digest_method: dig_alg,
          signature_method: sig_alg,
          authn_requests_signed: true,
          want_assertions_signed: true,
          logout_requests_signed: true,
          check_sp_cert_expiration: false # quando il certificato scade viene sollevata un eccezione
        }

      }
      let(:sp_entity_id) { "http://192.168.1.52/" }
      let(:strategy) { [described_class, saml_options] }
      let(:sso_params) {
        sso_params = {}
        sso_params["sso"] = { "idp" => "local2" }
        sso_params["spid_level"] = tenant.spid_level
        sso_params["host"] = tenant.sp_entity_id
        sso_params["relay_state"] = Base64.strict_encode64(tenant.relay_state)
        sso_params
      }

      before do
        Rack::Test::DEFAULT_HOST = URI(tenant.sp_entity_id).host
        allow(Decidim::Spid::Idp).to receive(:list).and_return(
          YAML.load_file(Rails.root.join('config', 'idp_list.yml')).dig("development").dig("spid")
        )
      end

      describe "#initialize" do
        subject do
          get "/users/auth/ciao/metadata"
        end

        shared_examples "an OmniAuth strategy" do
          it "applies the local options and the IdP metadata options" do
            expect(subject).to be_successful

            instance = last_request.env["omniauth.strategy"]

            expect(instance.options[:sp_entity_id]).to eq(
              "http://192.168.1.52/"
            )
            expect(instance.options[:certificate]).to eq(certificate.to_pem)
            expect(instance.options[:private_key]).to eq(private_key.to_pem)
            dig_alg = Decidim::Spid::Certificate.digest_algorithm(instance.options[:sha])
            sig_alg = Decidim::Spid::Certificate.signature_algorithm(instance.options[:sha])
            expect(instance.options[:security]).to include(
              {
                metadata_signed: true,
                digest_method: dig_alg,
                signature_method: sig_alg,
                authn_requests_signed: true,
                want_assertions_signed: true,
                logout_requests_signed: true,
                check_sp_cert_expiration: false # quando il certificato scade viene sollevata un eccezione
              }
            )

            # Check the automatically set options
            expect(instance.options[:assertion_consumer_service_url]).to eq(
              "http://192.168.1.52/users/auth/ciao/callback"
            )
            expect(instance.options[:sp_name_qualifier]).to eq(
              "http://192.168.1.52/"
            )
            # Check the most important metadata options
            expect(instance.options[:idp_entity_id]).to eq(
              "https://localhost:8443/demo"
            )
            expect(instance.options[:name_identifier_format]).to eq(
              "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
            )
            expect(instance.options[:idp_slo_service_url]).to eq(
              "https://localhost:8443/demo/samlsso"
            )
            expect(instance.options[:idp_sso_service_url]).to eq(
              "https://localhost:8443/demo/samlsso"
            )

            expect(instance.options[:idp_cert]).to eq(
              "MIIEGDCCAwCgAwIBAgIJAOrYj9oLEJCwMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAklUMQ4wDAYDVQQIEwVJdGFseTENMAsGA1UEBxMEUm9tZTENMAsGA1UEChMEQWdJRDESMBAGA1UECxMJQWdJRCBURVNUMRQwEgYDVQQDEwthZ2lkLmdvdi5pdDAeFw0xOTA0MTExMDAyMDhaFw0yNTAzMDgxMDAyMDhaMGUxCzAJBgNVBAYTAklUMQ4wDAYDVQQIEwVJdGFseTENMAsGA1UEBxMEUm9tZTENMAsGA1UEChMEQWdJRDESMBAGA1UECxMJQWdJRCBURVNUMRQwEgYDVQQDEwthZ2lkLmdvdi5pdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK8kJVo+ugRrbbv9xhXCuVrqi4B7/MQzQc62ocwlFFujJNd4m1mXkUHFbgvwhRkQqo2DAmFeHiwCkJT3K1eeXIFhNFFroEzGPzONyekLpjNvmYIs1CFvirGOj0bkEiGaKEs+/umzGjxIhy5JQlqXE96y1+Izp2QhJimDK0/KNij8I1bzxseP0Ygc4SFveKS+7QO+PrLzWklEWGMs4DM5Zc3VRK7g4LWPWZhKdImC1rnS+/lEmHSvHisdVp/DJtbSrZwSYTRvTTz5IZDSq4kAzrDfpj16h7b3t3nFGc8UoY2Ro4tRZ3ahJ2r3b79yK6C5phY7CAANuW3gDdhVjiBNYs0CAwEAAaOByjCBxzAdBgNVHQ4EFgQU3/7kV2tbdFtphbSA4LH7+w8SkcwwgZcGA1UdIwSBjzCBjIAU3/7kV2tbdFtphbSA4LH7+w8SkcyhaaRnMGUxCzAJBgNVBAYTAklUMQ4wDAYDVQQIEwVJdGFseTENMAsGA1UEBxMEUm9tZTENMAsGA1UEChMEQWdJRDESMBAGA1UECxMJQWdJRCBURVNUMRQwEgYDVQQDEwthZ2lkLmdvdi5pdIIJAOrYj9oLEJCwMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAJNFqXg/V3aimJKUmUaqmQEEoSc3qvXFITvT5f5bKw9yk/NVhR6wndL+z/24h1OdRqs76blgH8k116qWNkkDtt0AlSjQOx5qvFYh1UviOjNdRI4WkYONSw+vuavcx+fB6O5JDHNmMhMySKTnmRqTkyhjrch7zaFIWUSV7hsBuxpqmrWDoLWdXbV3eFH3mINA5AoIY/m0bZtzZ7YNgiFWzxQgekpxd0vcTseMnCcXnsAlctdir0FoCZztxMuZjlBjwLTtM6Ry3/48LMM8Z+lw7NMciKLLTGQyU8XmKKSSOh0dGh5Lrlt5GxIIJkH81C0YimWebz8464QPL3RbLnTKg+c="
            )
          end

          context "when the name identifier format is specified" do
            let(:saml_options) do
              {
                name: tenant.config[:name],
                sp_entity_id: sp_entity_id,
                certificate: certificate.to_pem,
                private_key: private_key.to_pem,
                security: security_options,
                issuer: sp_entity_id,
                sp_name_qualifier: tenant.omniauth_settings[:sp_name_qualifier],
                assertion_consumer_service_url: tenant.omniauth_settings[:assertion_consumer_service_url],
                single_logout_service_url: tenant.omniauth_settings[:single_logout_service_url],
              }.merge(idp_attributes)
            end

            it "uses the configured name identifier format" do
              expect(subject).to be_successful

              instance = last_request.env["omniauth.strategy"]

              expect(instance.options[:name_identifier_format]).to eq(
                "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
              )
            end
          end
        end

        it_behaves_like "an OmniAuth strategy" do
          let(:idp_metadata_file) { file_fixture("idp_metadata.xml") }
          let(:idp_metadata_url) { nil }
        end
      end

      describe "GET /users/auth/ciao" do
        it "signs the request" do
          expect{ get "/users/auth/ciao" }.to raise_error.with_message("Idp not found")

          get "/users/auth/ciao?sso[idp]=local2"
          location = URI.parse(last_response.location)
          query = Rack::Utils.parse_query location.query
          expect(query).to have_key("SAMLRequest")
          expect(query).to have_key("Signature")
          expect(query).to have_key("SigAlg")
          expect(query["SigAlg"]).to eq(XMLSecurity::Document::RSA_SHA256)
        end

        it "creates a valid SAML authn request" do
          expect(get "/users/auth/ciao?sso[idp]=local2").to be_redirect

          location = URI.parse(last_response.location)
          expect(location.scheme).to eq("https")
          expect(location.host).to eq("localhost")
          expect(location.port).to eq(8443)
          expect(location.path).to eq("/demo/samlsso")

          query = Rack::Utils.parse_query location.query

          deflated_xml = Base64.decode64(query["SAMLRequest"])
          xml = Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(deflated_xml)
          request = REXML::Document.new(xml)
          expect(request.root).not_to be_nil

          acs = request.root.attributes["AssertionConsumerServiceURL"]
          dest = request.root.attributes["Destination"]
          ii = request.root.attributes["IssueInstant"]

          expect(acs).to eq("http://192.168.1.52/users/auth/ciao/callback")
          expect(dest).to eq("https://localhost:8443/demo/samlsso")
          expect(ii).to match(/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z/)

          issuer = request.root.elements["saml:Issuer"]
          expect(issuer.text).to eq("http://192.168.1.52/")
        end
      end

      describe "POST /users/auth/ciao/callback" do
        subject { last_response }

        let(:xml) { :saml_response }

        context "when the response is valid" do
          let(:saml_options) do
            {
              name: tenant.config[:name],
              sp_entity_id: sp_entity_id,
              certificate: certificate.to_pem,
              private_key: private_key.to_pem,
              security: security_options,
              issuer: sp_entity_id,
              sp_name_qualifier: tenant.omniauth_settings[:sp_name_qualifier],
              assertion_consumer_service_url: tenant.omniauth_settings[:assertion_consumer_service_url],
              single_logout_service_url: tenant.omniauth_settings[:single_logout_service_url],
            }.merge(idp_attributes)
          end

          let(:custom_saml_attributes) { [] }

          let(:sign_certgen) { OmniAuth::Spid::Test::CertificateGenerator.new }
          let(:sign_certificate) { sign_certgen.certificate }
          let(:sign_private_key) { sign_certgen.private_key }
          let(:sso_params) {
            sso_params = {}
            sso_params["sso"] = { "idp" => "local2" }
            sso_params["spid_level"] = tenant.spid_level
            sso_params["host"] = tenant.sp_entity_id
            sso_params["relay_state"] = Base64.strict_encode64(tenant.relay_state)
            sso_params
          }

          before do
            allow(Time).to receive(:now).and_return(
              Time.utc(2022, 5, 10, 13, 4, 0)
            )

            allow(Decidim::Spid::Idp).to receive(:list).and_return(
              YAML.load_file(Rails.root.join('config', 'idp_list.yml')).dig("development").dig("spid")
            )

            allow_any_instance_of(OneLogin::RubySaml::Response).to receive(:validate_signature).and_return(true)

            saml_response = base64_file("#{xml}.xml")

            post(
              "/users/auth/ciao/callback",
              { "SAMLResponse" => saml_response },
              { "rack.session" => { :"ciao_spid_sso_params" => sso_params } }
                  # "rack.session.options" => request.session.options
            )
          end

          # it "sets the info hash correctly" do
          #   expect(auth_hash["info"].to_hash).to eq(
          #     "email"=>"aabyron@hotmail.com ", "first_name"=>nil, "last_name"=>nil, "name"=>"Ada "
          #   )
          # end
          # #
          # it "sets the raw info to all attributes" do
          #   expect(auth_hash["extra"]["raw_info"].all.to_hash).to eq(
          #                                                           {"address"=>["Via Listz 21 00144 Roma "], "dateOfBirth"=>["1985-12-10"], "digitalAddress"=>[""],
          #                                                            "email" => ["aabyron@hotmail.com "], "familyName" => ["Lovelace "], "name"=>["Ada "], "placeOfBirth"=>["G702 "],
          #                                                            "registeredOffice"=>[""], "spidCode"=>["SPID-002 "], "fingerprint" => "EF:DE:F0:ED:5D:55:7A:3D:0D:4B:BD:5D:C9:3C:EE:07:DF:F9:5F:CB",
          #                                                            "fiscalNumber" => ["TINIT-LVLDAA85T50G702B "], "gender" => ["F "], "idCard" => ["passaporto KK1234567 questuraLivorno 2016-09-04 2026-09-03 "],
          #                                                            "ivaCode" => [""], "mobilePhone" => ["3939393939 "]
          #                                                           }
          #   )
          # end

          describe "#response_object" do
            subject { instance.response_object }

            let(:instance) { last_request.env["omniauth.strategy"] }

            it "returns the response object" do
              expect(subject).to be_a(OneLogin::RubySaml::Response)
              expect(subject).to be_is_valid
            end
          end
        end

        context "when response is a logout response" do
          let(:relay_state) { Base64.strict_encode64("/relay/uri") }
          let(:sso_params) {
            sso_params = {}
            sso_params["sso"] = { "idp" => "local2" }
            sso_params["spid_level"] = tenant.spid_level
            sso_params["host"] = tenant.sp_entity_id
            sso_params["relay_state"] = relay_state
            sso_params
          }
          before do
            post  "/users/auth/ciao/slo",
              { "SAMLResponse" => base64_file("saml_logout_response.xml") },
              { "rack.session" => {
                :"ciao_spid_sso_params" => sso_params,
                "saml_transaction_id" => "_404e2e3c-9dc6-4250-a1d1-8c1eed66d7d0"
               }
              }
          end

          it "redirects to relaystate" do
            expect(last_response).to be_redirect
            expect(last_response.location).to eq("/users/slo_callback?success=true&path=/relay/uri")
          end

          context "with a full HTTP URI as relaystate" do
            let(:relay_state) { Base64.strict_encode64("http://www.mainiotech.fi/vuln") }

            it "redirects to the root path" do
              expect(last_response.location).to eq("/users/slo_callback?success=true&path=http://www.mainiotech.fi/vuln")
            end
          end

          context "with a full HTTPS URI as relaystate" do
            let(:relay_state) { Base64.strict_encode64("https://www.mainiotech.fi/vuln") }

            it "redirects to the slo callback path" do
              expect(last_response.location).to eq("/users/slo_callback?success=true&path=https://www.mainiotech.fi/vuln")
            end
          end

          context "with a non-protocol URI as relaystate" do
            let(:relay_state) { Base64.strict_encode64("//www.mainiotech.fi/vuln") }

            it "redirects to the slo callback path" do
              expect(last_response.location).to eq("/users/slo_callback?success=true&path=//www.mainiotech.fi/vuln")
            end
          end
        end

        shared_examples "replaced relay state" do
          it "adds root URI as the RelayState parameter to the response" do
            expect(last_response).to be_redirect

            location = URI.parse(last_response.location)
            query = Rack::Utils.parse_query location.query
            expect(query["RelayState"]).to eq("/")
          end
        end

        shared_examples "invalid relay states replaced" do
          context "with a full HTTP URI" do
            let(:relay_state) { "http://www.mainiotech.fi/vuln" }

            it_behaves_like "replaced relay state"
          end

          context "with a full HTTPS URI" do
            let(:relay_state) { "https://www.mainiotech.fi/vuln" }

            it_behaves_like "replaced relay state"
          end

          context "with a non-protocol URI" do
            let(:relay_state) { "//www.mainiotech.fi/vuln" }

            it_behaves_like "replaced relay state"
          end
        end

        context "when request is a logout request" do
          let(:sso_params) {
            sso_params = {}
            sso_params["sso"] = { "idp" => "local2" }
            sso_params["spid_level"] = tenant.spid_level
            sso_params["host"] = tenant.sp_entity_id
            sso_params["relay_state"] = Base64.strict_encode64(tenant.relay_state)
            sso_params
          }

          subject do
            post(
              "/users/auth/ciao/spslo",
              params,
              "rack.session" => {
                :"ciao_spid_sso_params" => sso_params,
                "ciao_spid_uid" => "_24e086cd-0d52-4f25-901e-e4e1bdef145f"
              }
            )
          end

          let(:params) { { "SAMLRequest" => base64_file("saml_logout_request.xml") } }

          context "when logout request is valid" do
            before { subject }

            it "redirects to logout response" do
              expect(last_response).to be_redirect
              expect(last_response.location).to match %r{https://localhost:8443/demo/samlsso}
            end
          end

          context "when RelayState is provided" do
            let(:params) do
              {
                "SAMLRequest" => base64_file("saml_logout_request.xml"),
                "RelayState" => Base64.strict_encode64(relay_state)
              }
            end
            let(:relay_state) { nil }

            before { subject }

            context "with a valid value" do
              let(:relay_state) { "/" }

              it "adds the RelayState parameter to the response" do
                expect(last_response).to be_redirect

                location = URI.parse(last_response.location)
                query = Rack::Utils.parse_query location.query
                expect(query["RelayState"]).to eq(relay_state)
              end
            end

            it_behaves_like "invalid relay states replaced"
          end
        end

        context "when sp initiated SLO" do
          let(:params) { }

          before { post("/users/auth/ciao/spslo",
                        params,
                        { "rack.session" => {
                            :"ciao_spid_sso_params" => sso_params,
                            "saml_transaction_id" => "_404e2e3c-9dc6-4250-a1d1-8c1eed66d7d0"
                          }
                        }
          ) }

          it "redirects to logout request" do
            expect(last_response).to be_redirect
            expect(last_response.location).to match %r{https://localhost:8443/demo/samlsso}
          end

        end
      end

      describe "GET /users/auth/ciao/metadata" do
        subject { get "/users/auth/ciao/metadata" }

        let(:response_xml) { Nokogiri::XML(last_response.body) }
        let(:request_attribute_nodes) do
          response_xml.xpath(
            "//md:EntityDescriptor//md:SPSSODescriptor//md:AttributeConsumingService//md:RequestedAttribute"
          )
        end
        let(:request_attributes) do
          request_attribute_nodes.map do |node|
            {
              friendly_name: node["FriendlyName"],
              name: node["Name"]
            }
          end
        end

        it "adds the correct request attributes" do
          expect(subject).to be_successful
          expect(request_attributes).to match_array([{:friendly_name=>"Nome", :name=>"name"}, {:friendly_name=>"Cognome", :name=>"familyName"}, {:friendly_name=>"Codice Fiscale", :name=>"fiscalNumber"}, {:friendly_name=>"Codice SPID", :name=>"spidCode"}, {:friendly_name=>"Email", :name=>"email"}, {:friendly_name=>"Genere", :name=>"gender"}, {:friendly_name=>"Data di nascita", :name=>"dateOfBirth"}, {:friendly_name=>"Luogo di nascita", :name=>"placeOfBirth"}, {:friendly_name=>"registeredOffice", :name=>"registeredOffice"}, {:friendly_name=>"Partita IVA", :name=>"ivaCode"}, {:friendly_name=>"ID Carta", :name=>"idCard"}, {:friendly_name=>"Numero di telefono", :name=>"mobilePhone"}, {:friendly_name=>"Indirizzo", :name=>"address"}, {:friendly_name=>"Indirizzo digitale", :name=>"digitalAddress"}])
        end

        context "when IdP metadata URL is not available" do
          let(:idp_metadata_url) { nil }

          it "responds to the metadata request" do
            expect(subject).to be_successful
          end
        end
      end
    end
  end
end
