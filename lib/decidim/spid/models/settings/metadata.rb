# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Validazioni extra per il metadata
module Decidim
  module Spid
    module Settings

      class Metadata < Base

        def initialize(spid_params)
          super

          metadata_attributes = settings
          metadata_attributes[:certificate_new] = @new_certificate || File.read("#{new_certificate_path}") if @new_certificate || (new_certificate_path && File.exists?(new_certificate_path))
          @settings = metadata_attributes
        end

        protected

        def validate!
          errors << 'EntityID deve essere presente (impostare issuer)' if sp_attributes[:issuer].blank?
          errors << 'Signature deve essere presente (impostare private_key)' if sp_attributes[:private_key].blank?
          errors << 'Signature deve essere presente (impostare certificate)' if sp_attributes[:certificate].blank?

          validate_signature_encryption
          validate_digest_encryption
          validate_key_size

          true
        end

        def validate_signature_encryption
          signature_algorithms = Decidim::Spid::Certificate.signature_algorithms
          if signature_algorithms.exclude?(sp_attributes.dig(:security, :signature_method))
            errors << 'Signature deve essere presente (impostare encryption sha a 1, 256, 384, 512)'
          end
        end

        def validate_digest_encryption
          digest_algorithms = Decidim::Spid::Certificate.digest_algorithms
          if digest_algorithms.exclude?(sp_attributes.dig(:security, :digest_method))
            errors << 'Signature deve essere presente (impostare encryption sha a 1, 256, 384, 512)'
          end
        end

        def validate_key_size
          return unless sp_attributes[:private_key]
          key = OpenSSL::PKey::RSA.new(sp_attributes[:private_key])
          key_size = key.n.num_bytes * 8
          if key_size < 1024
            errors << 'Signature deve essere presente (impostare una chiave di almeno a 1024 bit'
          end
        end

      end
    end
  end
end
