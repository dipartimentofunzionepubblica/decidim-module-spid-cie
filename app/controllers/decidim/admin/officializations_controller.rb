# frozen_string_literal: true

require_dependency Decidim::Admin::Engine.root.join('app', 'controllers', 'decidim', 'admin', 'officializations_controller').to_s

module Decidim
  module Admin
    # Controller that allows managing user officializations at the admin panel.
    #
    class OfficializationsController < Decidim::Admin::ApplicationController
      include Decidim::Admin::Officializations::FilterableOverrides

    end
  end
end
