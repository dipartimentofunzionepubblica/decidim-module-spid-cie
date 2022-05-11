# frozen_string_literal: true

require_dependency "decidim/components/namer"

Decidim.register_component(:decidim_cie) do |component|
  component.engine = Decidim::Cie::Engine
  component.admin_engine = Decidim::Cie::AdminEngine
  component.icon = "decidim/cie/cie-logo.svg"

  component.admin_stylesheet = "decidim/cie/admin/application"
  component.stylesheet = "decidim/cie/cie"
end
