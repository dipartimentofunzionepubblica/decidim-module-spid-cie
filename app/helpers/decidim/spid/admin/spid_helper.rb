# frozen_string_literal: true

module Decidim
  module Spid
    # Custom helpers, scoped to the spid engine.
    module Admin
      module SpidHelper

        # include Decidim::Proposals::ApplicationHelper
        # include Decidim::Proposals::Engine.routes.url_helpers
        # include Decidim::LayoutHelper
        # include Decidim::ResourceReferenceHelper
        # include Decidim::TranslatableAttributes
        # include Decidim::CardHelper

        def cie_icon
          content_tag :span, class: 'cie-badge' do
            image_tag 'decidim/cie/Logo_CIE_ID.svg', alt: "CIE ID Icon"
          end
        end

        def spid_icon
          content_tag :span, class: 'spid-badge' do
            image_tag 'decidim/spid/spid-logo.svg', alt: "Spid Icon"
          end
        end
      end
    end
  end
end
