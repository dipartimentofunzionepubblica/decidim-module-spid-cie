# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module Spid
    # This is the engine that runs on the public interface of spid.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Spid

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

      initializer "decidim_spid.mount_routes", before: :add_routing_paths do
        Decidim::Core::Engine.routes.prepend do
          mount Decidim::Spid::Engine => "/"
        end
      end

      initializer "decidim_spid.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "decidim_spid.setup", before: "devise.omniauth" do
        Decidim::Spid.setup!
      end

      overrides = "#{Decidim::Spid::Engine.root}/app/overrides"
      # Rails.autoloaders.main.ignore(overrides)
      config.to_prepare do
        Dir.glob("#{overrides}/**/*_override.rb").each do |override|
          load override
        end
      end

    end
  end
end
