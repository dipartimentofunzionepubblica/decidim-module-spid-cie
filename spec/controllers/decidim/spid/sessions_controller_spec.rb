# # frozen_string_literal: true
#
# require "spec_helper"
#
# module Decidim
#   module Spid
#     # Tests the session destroying functionality with the SPID module.
#     # Note that this is why we are using the `:request` type instead
#     # of `:controller`, so that we get the OmniAuth middleware applied to the
#     # requests and the SPID OmniAuth strategy to handle endpoints. Another
#     # reason is to test the sign out path override.
#     describe SessionsController, type: :request do
#       let(:tenant) { Decidim::Spid.tenants.first }
#       let(:organization) { create(:organization, host: URI(tenant.sp_entity_id).host) }
#
#       # For testing with signed in user
#       let(:confirmed_user) do
#         create(:user, :confirmed, organization: organization)
#       end
#
#       before do
#         allow(Decidim::Spid::Idp).to receive(:list).and_return(
#           YAML.load_file(Rails.root.join('config', 'idp_list.yml')).dig("development").dig("spid")
#         )
#
#         # Set the correct host
#         host! organization.host
#       end
#
#       describe "POST destroy" do
#         before do
#           sign_in confirmed_user
#         end
#
#         context "when there is no active Spid sign in" do
#           it "signs out the user normally" do
#             post "/users/sign_out"
#
#             expect(response).to redirect_to("/")
#             expect(controller.current_user).to be_nil
#           end
#         end
#
#         context "when there is an active SPID sign in" do
#           before do
#             # Generate a dummy session by requesting the home page.
#             get "/"
#             request.session["decidim-spid.signed_in"] = true
#             request.session["decidim-spid.tenant"] = "ciao"
#           end
#
#           it "signs out the user through the SPID SLO" do
#             post "/users/sign_out", env: {
#               "rack.session" => request.session,
#               "rack.session.options" => request.session.options
#             }
#
#             expect(response).to redirect_to("http://192.168.1.52/users/auth/ciao/spslo")
#           end
#
#         end
#       end
#
#       describe "POST slo" do
#         let(:saml_response) do
#           resp_xml = saml_response_from_file("saml_logout_response.xml")
#           Base64.strict_encode64(resp_xml)
#         end
#
#         let(:saml_request) do
#           resp_xml = saml_response_from_file("saml_logout_request.xml")
#           Base64.strict_encode64(resp_xml)
#         end
#
#         it "responds successfully to a SAML response" do
#           get "/"
#           request.session["ciao_spid_sso_params"] = sso_params
#           request.session["ciao_spid_transaction_id"] = "_404e2e3c-9dc6-4250-a1d1-8c1eed66d7d0"
#
#           get "/users/auth/ciao/spslo", params: { SAMLRequest: saml_request }, env: {
#             "rack.session" => request.session,
#             "rack.session.options" => request.session.options
#           }
#
#           expect(response).to be_redirect
#           expect(response.location).to eq("/")
#         end
#
#         let(:sso_params) {
#           sso_params = {}
#           sso_params["sso"] = { "idp" => "local2" }
#           sso_params["spid_level"] = tenant.spid_level
#           sso_params["host"] = tenant.sp_entity_id
#           sso_params["relay_state"] = Base64.strict_encode64(tenant.relay_state)
#           sso_params
#         }
#         # before do
#         #   post  "/users/auth/ciao/slo",
#         #         { "SAMLResponse" => base64_file("saml_logout_response.xml") },
#         #         { "rack.session" => {
#         #           :"ciao_spid_sso_params" => sso_params,
#         #           "saml_transaction_id" => "_404e2e3c-9dc6-4250-a1d1-8c1eed66d7d0"
#         #         }
#         #         }
#         # end
#
#         # it "responds successfully to a SAML request" do
#         #   # Generate a dummy session by requesting the home page.
#         #   get "/"
#         #   request.session["ciao_spid_sso_params"] = sso_params
#         #   request.session["ciao_spid_transaction_id"] = "_404e2e3c-9dc6-4250-a1d1-8c1eed66d7d0"
#         #
#         #   get "/users/auth/ciao/slo", { params: { SAMLRequest: saml_request }, env: {
#         #     "rack.session" => request.session,
#         #     "rack.session.options" => request.session.options
#         #   }}
#         #
#         #   expect(response).to be_redirect
#         #   expect(response.location).to match %r{https://login.microsoftonline.com/987f6543-1e0d-12a3-45b6-789012c345de/saml2}
#         # end
#       end
#       #
#       # describe "POST spslo" do
#       #   it "signs out the user through the MSAD SLO" do
#       #     post "/users/auth/msad/spslo"
#       #
#       #     expect(response).to be_redirect
#       #     expect(response.location).to match %r{https://login.microsoftonline.com/987f6543-1e0d-12a3-45b6-789012c345de/saml2}
#       #   end
#       #
#       #   it "preserves the flash messages after destroying the session" do
#       #     # Generate a dummy session by requesting the home page.
#       #     get "/"
#       #
#       #     # Set some arbitrary session variables to pass to the next request
#       #     request.session["test"] = "this should be removed"
#       #     request.session["warden.user.user.key"] = [[123], "abc"]
#       #     request.session["warden.user.user.session"] = { "last_request_at" => Time.now.to_i }
#       #
#       #     # See how the flash value is converted to a session variable:
#       #     # https://github.com/rails/rails/blob/12aabe2ee1d97be7a0ca093290a98e21a10d909c/actionpack/lib/action_dispatch/middleware/flash.rb#L138
#       #     request.session["flash"] = {
#       #       "discard" => [],
#       #       "flashes" => {
#       #         alert: "Alert message"
#       #       }
#       #     }
#       #
#       #     post "/users/auth/msad/spslo", env: {
#       #       "rack.session" => request.session,
#       #       "rack.session.options" => request.session.options
#       #     }
#       #
#       #     # Check that all other session keys were removed along with the logout
#       #     # request before redirecting the user.
#       #     expect(request.session).not_to include(
#       #       "test",
#       #       "warden.user.user.key",
#       #       "warden.user.user.session"
#       #     )
#       #     expect(request.session).to include("flash")
#       #     expect(flash[:alert]).to eq("Alert message")
#       #   end
#       # end
#       #
#       # describe "GET slo_callback" do
#       #   it "redirects the user to after sign in path" do
#       #     get "/users/slo_callback"
#       #
#       #     expect(response).to redirect_to("/")
#       #     expect(flash[:notice]).to be_nil
#       #   end
#       #
#       #   context "with the success flag" do
#       #     it "redirects the user to after sign in path and sets a notice" do
#       #       get "/users/slo_callback", params: { success: "1" }
#       #
#       #       expect(response).to redirect_to("/")
#       #       expect(flash[:notice]).to eq("Signed out successfully.")
#       #     end
#       #   end
#       # end
#
#       def saml_response_from_file(file)
#         filepath = file_fixture(file)
#         file_io = IO.read(filepath)
#         doc = Nokogiri::XML::Document.parse(file_io)
#
#         yield doc if block_given?
#
#         doc.to_s
#       end
#     end
#   end
# end
