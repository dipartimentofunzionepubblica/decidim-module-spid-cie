# frozen_string_literal: true

require "rails"
require "active_support/all"

require "decidim/core"

module Decidim
  module Spid
    # This is the engine that runs on the public interface of `Spid`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Spid::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        # Add admin engine routes here
        scope :admin do
          scope :spid do
            resources :exports, only: [:index]
          end
        end
      end

      initializer "decidim_spid_admin.mount_routes", before: "decidim_admin.mount_routes" do
        # Mount the engine routes to Decidim::Core::Engine because otherwise
        # they would not get mounted properly.
        Decidim::Admin::Engine.routes.append do
          mount Decidim::Spid::AdminEngine => "/"
        end
      end

      initializer "decidim_spid.action_controller" do |_app|
        ActiveSupport.on_load :action_controller do
          helper Decidim::Spid::Admin::SpidHelper
        end
      end

      # per forzare il reload degli helper. Necessario sicuramente in sviluppo
      config.to_prepare do
        ApplicationController.helper(Decidim::LayoutHelper)
      end

      def load_seed
        nil
      end
    end
  end
end
