# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module Cie
    # This is the engine that runs on the public interface of cie.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Cie

      routes do
        devise_scope :user do
          # Manually map the sign out path in order to control the sign out flow
          # through OmniAuth when the user signs out from the service. In these
          # cases, the user needs to be also signed out from the AD federation
          # server which is handled by the OmniAuth strategy.
          match(
            "/users/sign_out",
            to: "sessions#destroy",
            as: "destroy_user_session",
            via: [:delete, :post]
          )

          # This is the callback route after a returning from a successful sign
          # out request through OmniAuth.
          match(
            "/users/slo_callback",
            to: "sessions#slo_callback",
            as: "slo_callback_user_session",
            via: [:get]
          )
        end
      end

      initializer "decidim_cie.mount_routes", before: :add_routing_paths do
        Decidim::Core::Engine.routes.prepend do
          mount Decidim::Cie::Engine => "/"
        end
      end

      initializer "decidim_cie.assets" do |app|
        app.config.assets.precompile += %w(decidim/cie/*)
      end

      initializer "decidim_cie.setup", before: "devise.omniauth" do
        Decidim::Cie.setup!
      end

    end
  end
end
