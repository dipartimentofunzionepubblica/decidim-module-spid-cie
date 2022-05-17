# frozen_string_literal: true

module Decidim
  # This holds the decidim-core version.
  module Spid
    def self.version
      "#{decidim_version}.1"
    end

    def self.decidim_version
      "0.24.3"
    end
  end
end
