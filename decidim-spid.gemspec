# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/spid/version"

Gem::Specification.new do |s|
  s.version = Decidim::Spid.version
  s.authors = ["Lorenzo Angelone"]
  s.email = ["l.angelone@kapusons.it"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/decidim/decidim-module-spid"
  s.required_ruby_version = ">= 2.7"

  s.name = "decidim-spid"
  s.summary = "A decidim spid module"
  s.description = "SPID & CIE Integration for Decidim."

  s.files = Dir["{app,config,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "decidim-core", Decidim::Spid.decidim_version
  s.add_dependency "omniauth", "~> 1.9"
  s.add_dependency 'ruby-saml', '~> 1.14.0'
end
