# frozen_string_literal: true

module Decidim
  module Spid
    module Admin
      # Custom helpers, scoped to the spid engine.

      module ApplicationHelper

        def cie_icon
          content_tag :span, class: 'cie-badge' do
            image_pack_tag 'media/images/Logo_CIE_ID.svg', alt: "CIE ID Icon"
          end
        end

        def spid_icon
          content_tag :span, class: 'spid-badge' do
            image_pack_tag 'media/images/spid-logo.svg', alt: "Spid Icon"
          end
        end
      end
    end
  end
end
