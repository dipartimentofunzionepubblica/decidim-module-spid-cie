# frozen_string_literal: true

require_dependency "decidim/components/namer"

Decidim.register_component(:decidim_spid) do |component|
  component.engine = Decidim::Spid::Engine
  component.admin_engine = Decidim::Spid::AdminEngine
  component.icon = "decidim/spid/spid-logo.svg"

  component.admin_stylesheet = "decidim/spid/admin/application"
  component.stylesheet = "decidim/spid/spid"
end
