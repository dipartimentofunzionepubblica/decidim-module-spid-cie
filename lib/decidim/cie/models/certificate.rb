# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

module Decidim
  module Cie
    class Certificate

      def self.signature_algorithm sha
        case sha.to_s
        when '256'
          XMLSecurity::Document::RSA_SHA256
        when '384'
          XMLSecurity::Document::RSA_SHA384
        when '512'
          XMLSecurity::Document::RSA_SHA512
        end
      end

      def self.digest_algorithm sha
        case sha.to_s
        when '256'
          XMLSecurity::Document::SHA256
        when '384'
          XMLSecurity::Document::SHA384
        when '512'
          XMLSecurity::Document::SHA512
        end
      end

      def self.signature_algorithms
        [
          XMLSecurity::Document::RSA_SHA256,
          XMLSecurity::Document::RSA_SHA384,
          XMLSecurity::Document::RSA_SHA512,
        ]
      end

      def self.digest_algorithms
        [
          XMLSecurity::Document::SHA256,
          XMLSecurity::Document::SHA384,
          XMLSecurity::Document::SHA512,
        ]
      end

    end

  end
end