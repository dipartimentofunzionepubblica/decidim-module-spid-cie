# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Spid
    module Verification
      describe AuthorizationsController, type: :controller do
        routes { Decidim::Spid::Verification::Engine.routes }

        let(:user) { create(:user, :confirmed) }

        before do
          request.env["decidim.current_organization"] = user.organization
          sign_in user, scope: :user
        end

        describe "GET new" do
          it "render authorization the user" do
            get :new
            expect(response).to have_http_status(200)
          end
        end
      end
    end
  end
end
