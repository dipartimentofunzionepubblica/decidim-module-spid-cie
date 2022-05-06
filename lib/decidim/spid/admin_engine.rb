# frozen_string_literal: true

module Decidim
  module Spid
    # This is the engine that runs on the public interface of `Spid`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Spid::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        # Add admin engine routes here
        # resources :spid do
        #   collection do
        #     resources :exports, only: [:create]
        #   end
        # end
        # root to: "spid#index"
      end

      def load_seed
        nil
      end
    end
  end
end
