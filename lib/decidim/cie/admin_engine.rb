# frozen_string_literal: true

require "rails"
require "active_support/all"

require "decidim/core"

module Decidim
  module Cie
    # This is the engine that runs on the public interface of `Cie`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Cie::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      def load_seed
        nil
      end
    end
  end
end
