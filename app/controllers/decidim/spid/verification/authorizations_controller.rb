# frozen_string_literal: true

module Decidim
  module Spid
    module Verification
      class AuthorizationsController < ::Decidim::Verifications::ApplicationController
        skip_before_action :store_current_location

        helper_method :handler, :unauthorized_methods, :authorization_method, :authorization

        # todo: remove unnecessary
        include Decidim::UserProfile
        include Decidim::Verifications::Renewable
        helper Decidim::DecidimFormHelper
        helper Decidim::CtaButtonHelper
        helper Decidim::AuthorizationFormHelper
        helper Decidim::TranslationsHelper

        layout "layouts/decidim/user_profile", only: [:new]

        def new
          # Do not enforce the permission here because it would cause
          # re-authorizations not to work as the authorization already exists.
          # In case the user wants to re-authorize themselves, they can just
          # hit this endpoint again.
          # redirect_to decidim.user_spid_omniauth_authorize_path
          render :new
          #todo: if logged
        end
      end
    end
  end
end