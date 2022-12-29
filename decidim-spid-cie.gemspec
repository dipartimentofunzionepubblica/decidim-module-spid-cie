# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/spid/version"

Gem::Specification.new do |s|
  s.version = Decidim::Spid.version
  s.authors = ["Lorenzo Angelone"]
  s.email = ["l.angelone@kapusons.it"]
  s.licenses = ["MIT"]
  s.homepage = "https://github.com/dipartimentofunzionepubblica/decidim-module-spic-cie"
  s.required_ruby_version = ">= 2.7"

  s.name = "decidim-spid-cie"
  s.summary = "A decidim SPID & CIE module"
  s.description = "SPID & CIE Integration for Decidim."

  s.files = Dir["{app,config,lib}/**/*", "Rakefile", "README.md"]

  s.add_dependency "decidim-core", "#{Decidim::Spid.decidim_version}"
  s.add_dependency "omniauth", ">= 1.9"
  s.add_dependency 'ruby-saml', '~> 1.14.0'
  s.add_dependency "deface", '1.9.0'
end
