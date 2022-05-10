# frozen_string_literal: true

module Decidim
  module Spid
    # Custom helpers, scoped to the spid engine.
    module Admin
      module SpidHelper

        def spid_icon
          content_tag :span, class: 'spid-badge' do
            image_tag 'decidim/spid/spid-logo.svg', alt: "Spid Icon"
          end
        end
      end
    end
  end
end
