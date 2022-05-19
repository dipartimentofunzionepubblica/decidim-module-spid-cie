# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Spid

    describe OmniauthCallbacksController, type: :request do
      let(:tenant) { Decidim::Spid.tenants.first }
      let(:organization) { create(:organization, host: URI(tenant.sp_entity_id).host) }

      # For testing with signed in user
      let(:identity) do
        i = create(:identity, provider: "ciao")
        create(:authorization, user: i.user, name: "ciao_identity", metadata: {
          "name" => "Matti Mainio",
          "first_name" => "Matti",
          "last_name" => "Mainio",
          "nickname" => "mama"
        })
        i
      end

      before do
        Rack::Test::DEFAULT_HOST = URI(tenant.sp_entity_id).host
        # Make the time validation of the SAML response work properly
        allow(Time).to receive(:now).and_return(
          Time.utc(2020, 9, 2, 6, 0, 0)
        )

        allow(Decidim::Spid::Idp).to receive(:list).and_return(
          YAML.load_file(Rails.root.join('config', 'idp_list.yml')).dig("development").dig("spid")
        )

        # Configure the metadata attributes to be collected
        tenant.metadata_attributes = {
          name: "name",
          surname: "familyName",
          fiscal_code: 'fiscalNumber',
          gender: 'gender',
          birthday: 'dateOfBirth',
          birthplace: "placeOfBirth",
          company_name: "companyName",
          registered_office: "registeredOffice",
          iva_code: "ivaCode",
          id_card: 'idCard',
          mobile_phone: 'mobilePhone',
          email: 'email',
          address: 'address',
          digital_address: 'digitalAddress'
        }

        OmniAuth.config.before_callback_phase do |env|
          strategy = env["omniauth.strategy"]
          strategy.options[:assertion_consumer_service_url] = "/users/auth/ciao/callback"
        end
        OmniAuth.config.path_prefix = ""

        # Set the correct host
        host! URI(organization.host).host
      end

      after do
        # Reset the metadata attributes back to defaults
        tenant.metadata_attributes = {}

        # Reset the before_callback_phase for the other tests
        OmniAuth.config.before_callback_phase {}
      end

      describe "GET spid" do
        let(:user_identifier) { "SPID-002" }
        let(:saml_attributes_base) do
          {
            "name" => ["Matti"],
            "familyName" => ["Mainio"],
          }
        end
        let(:saml_attributes) do
          {
            "fiscalNumber" => ["TINIT-LVLDAA85T50G702B"],
            "spidCode" => ["SPID-002"],
            "email" => ["aabyron@hotmail.com"],
            "gender" => ["F"],
            "dateOfBirth" => ["1985-07-15"],
            "placeOfBirth" => ["G702"],
            "registeredOffice" => [""],
            "ivaCode" => [""],
            "idCard" => ["passaporto KK1234567 questuraLivorno 2016-09-04 2026-09-03"],
            "mobilePhone" => ["123456"],
            "address" => ["Via Listz 21 00144 Roma"],
            "digitalAddress" => [""],
            "fingerprint" => "EF:DE:F0:ED:5D:55:7A:3D:0D:4B:BD:5D:C9:3C:EE:07:DF:F9:5F:CB"
          }
        end
        let(:saml_response) do
          attrs = saml_attributes_base.merge(saml_attributes)
          resp_xml = generate_saml_response(attrs)
          Base64.strict_encode64(resp_xml)
        end

        it "creates a new user record with the returned SAML attributes" do
          omniauth_callback_get

          user = User.last

          expect(user.name).to eq("Matti Mainio")
          expect(user.nickname).to eq("matti_mainio")

          authorization = Authorization.find_by(
            user: user,
            name: "ciao_identity"
          )
          expect(authorization).not_to be_nil

          expect(authorization.metadata).to include(
                                              {"name"=>"Matti", "email"=>"aabyron@hotmail.com", "gender"=>"F", "address"=>"Via Listz 21 00144 Roma", "id_card"=>"passaporto KK1234567 questuraLivorno 2016-09-04 2026-09-03", "surname"=>"Mainio", "birthday"=>"1985-07-15", "birthplace"=>"G702", "fiscal_code"=>"TINIT-LVLDAA85T50G702B", "mobile_phone"=>"123456"}
          )
        end

        it "redirects to the root path by default after a successful registration and first sign in" do
          omniauth_callback_get

          user = User.last

          expect(user.sign_in_count).to eq(1)
          expect(response).to redirect_to("/")
        end

        context "when uid is returned from the IdP that matches existing user" do
          let(:saml_attributes) do
            {
              "spidCode" => [identity.uid]
            }
          end

          it "hijacks the account for the returned email" do
            Decidim::User.destroy_all
            omniauth_callback_get(identity: identity)

            authorization = Authorization.find_by(
              user: identity.user,
              name: "ciao_identity"
            )
            expect(authorization).not_to be_nil
            expect(authorization.metadata).to include(
              "name" => "Matti",
              "surname" => "Mainio",
            )

            warden = request.env["warden"]
            current_user = warden.authenticate(scope: :user)
            expect(current_user).to eq(identity.user)
          end
        end

        context "when the user is already signed in" do
          before do
            sign_in identity.user
          end

          it "adds the authorization to the signed in user" do
            omniauth_callback_get(identity: identity)

            expect(identity.user.name).not_to eq("Matti Mainio")
            expect(identity.user.nickname).not_to eq("matti_mainio")

            authorization = Authorization.find_by(
              user: identity.user,
              name: "ciao_identity"
            )
            expect(authorization).not_to be_nil

            expect(authorization.metadata).to include(
                                                {"name"=>"Matti", "email"=>"aabyron@hotmail.com", "gender"=>"F", "address"=>"Via Listz 21 00144 Roma", "id_card"=>"passaporto KK1234567 questuraLivorno 2016-09-04 2026-09-03", "surname"=>"Mainio", "birthday"=>"1985-07-15", "birthplace"=>"G702", "fiscal_code"=>"TINIT-LVLDAA85T50G702B", "mobile_phone"=>"123456"}
            )
          end

          it "redirects to the root path" do
            omniauth_callback_get(identity: identity)

            expect(response).to redirect_to("/")
          end
        end

        context "when the user is already signed in and authorized" do
          let!(:authorization) do
            signature = OmniauthRegistrationForm.create_signature(
              :ciao,
              identity.uid
            )
            authorization = Decidim::Authorization.last
            authorization.assign_attributes(
              user: identity.user,
              name: "ciao_identity",
              attributes: {
                unique_id: signature,
                metadata: {}
              }
            )
            authorization.save!
            authorization.grant!
            authorization
          end

          before do
            sign_in identity.user
          end

          it "updates the existing authorization" do
            omniauth_callback_get(identity: identity)

            # Check that the user record was NOT updated
            expect(identity.user.name).not_to eq("Matti Mainio")
            expect(identity.user.nickname).not_to eq("matti_mainio")

            # Check that the authorization is the same one
            authorizations = Authorization.where(
              user: identity.user,
              name: "ciao_identity"
            )
            expect(authorizations.count).to eq(1)
            expect(authorizations.first).to eq(authorization)

            # Check that the metadata was updated
            expect(authorizations.first.metadata).to include(
                                                       {"name"=>"Matti", "email"=>"aabyron@hotmail.com", "gender"=>"F", "address"=>"Via Listz 21 00144 Roma", "id_card"=>"passaporto KK1234567 questuraLivorno 2016-09-04 2026-09-03", "surname"=>"Mainio", "birthday"=>"1985-07-15", "birthplace"=>"G702", "fiscal_code"=>"TINIT-LVLDAA85T50G702B", "mobile_phone"=>"123456"}
            )
          end
        end

        def omniauth_callback_get(identity: nil)
          sso_params = {}
          sso_params["sso"] = { "idp" => "local" }
          sso_params["cie_level"] = 2
          sso_params["host"] = host
          sso_params["relay_state"] = host
          sso_params

          r = Decidim::Spid::SsoResponse.new(saml_response, sso_params, tenant.config)

          # Call the endpoint with the SAML response
          get "/users/auth/ciao/callback",
              { params: { SAMLResponse: saml_response},
                env: {
                  "rack.session" => { :"ciao_spid_sso_params" => sso_params, "ciao_spid_uid" => r.response.attributes[tenant.config.uid_attribute] || r.response.name_id.try(:strip) },
                  "rack.session.options" => {},
                  "decidim.current_organization" => identity.try(:organization) || organization,
                  "omniauth.auth" => {
                    "provider" => "ciao",
                    "uid" => identity.try(:uid) || "SPID-002",
                    "nickname" => "matti-mainio",
                    "info" => {
                      "name" => "Matti Mainio",
                      "email" => "aabyron@hotmail.com",
                    },
                    "credentials" => {},
                    "extra" => {
                      "raw_info" => r.response.attributes,
                      "session_index" => nil,
                      "response_object" => r.response
                    }
                  }
                }}
        end
      end

      def generate_saml_response(attributes = {})
        saml_response_from_file("saml_response_blank.xml", sign: true) do |doc|
          root_element = doc.root
          statements_node = root_element.at_xpath(
            "//saml:Assertion//saml:AttributeStatement",
            saml: "urn:oasis:names:tc:SAML:2.0:assertion"
          )

          if attributes.blank?
            statements_node.remove
          else
            attributes.each do |name, value|
              attr_element = Nokogiri::XML::Node.new "Attribute", doc
              attr_element["Name"] = name
              Array(value).each do |item|
                next if item.blank?

                attr_element.add_child("<AttributeValue>#{item}</AttributeValue>")
              end

              statements_node.add_child(attr_element)
            end
          end

          yield doc if block_given?
        end
      end

      def saml_response_from_file(file, sign: false)
        filepath = file_fixture(file)
        file_io = IO.read(filepath)
        doc = Nokogiri::XML::Document.parse(file_io)

        yield doc if block_given?

        doc = sign_xml(doc) if sign

        doc.to_s
      end

      def sign_xml(xml_doc)
        cert = OpenSSL::X509::Certificate.new(File.read(file_fixture(".keys/certificate.pem")))
        pkey = OpenSSL::PKey::RSA.new(File.read(file_fixture(".keys/private_key.pem")))

        # doc = XMLSecurity::Document.new(xml_string)
        # doc = Nokogiri::XML::Document.parse(xml_string)
        assertion_node = xml_doc.root.at_xpath(
          "//saml:Assertion",
          saml: "urn:oasis:names:tc:SAML:2.0:assertion"
        )

        # The assertion node needs to be canonicalized in order for the digests
        # to match because the canonicalization handles specific elements in the
        # XML a bit differently which causes different XML output on some nodes
        # such as the `<SubjectConfirmationData>` node.
        noko = Nokogiri::XML(assertion_node.to_s) do |config|
          config.options = XMLSecurity::BaseDocument::NOKOGIRI_OPTIONS
        end
        assertion_canon = noko.canonicalize(
          Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0,
          XMLSecurity::Document::INC_PREFIX_LIST.split(" ")
        )

        assertion_doc = XMLSecurity::Document.new(assertion_canon)
        assertion_doc.sign_document(
          pkey,
          cert,
          XMLSecurity::Document::RSA_SHA256,
          XMLSecurity::Document::SHA256
        )
        assertion = Nokogiri::XML::Document.parse(assertion_doc.to_s)
        signature = assertion.root.at_xpath(
          "//ds:Signature",
          ds: "http://www.w3.org/2000/09/xmldsig#"
        )

        # Remove blanks from the signature according to:
        # https://stackoverflow.com/a/35806327
        #
        # This is needed in order for the signature validation to succeed.
        # Otherwise it would fail because the signature is validated against the
        # signature node without any intendation or blanks between the XML tags.
        # We need a separate document for this in order for the blank removal to
        # work correctly.
        signature_doc = Nokogiri::XML::Document.parse(signature.to_s)
        signature_doc.search("//text()").each do |text_node|
          text_node.content = "" if text_node.content.strip.empty?
        end
        signature = signature_doc.root.at_xpath(
          "//ds:Signature",
          ds: "http://www.w3.org/2000/09/xmldsig#"
        )

        # Inject the signature to the correct place in the document
        issuer = xml_doc.root.at_xpath(
          "//saml2:Assertion//saml2:Issuer",
          saml2: "urn:oasis:names:tc:SAML:2.0:assertion"
        )
        issuer.after(signature.to_s)

        xml_doc
      end
    end
  end
end
