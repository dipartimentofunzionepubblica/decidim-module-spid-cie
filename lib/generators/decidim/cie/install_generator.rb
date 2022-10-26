# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

require 'decidim/spid/secret_modifier'

module Decidim
  module Cie
    module Generators
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path('templates', __dir__)

        desc "Crea un Decidim CIE Tenant"

        argument :tenant_name, type: :string
        argument :entity_id, type: :string

        def copy_initializer
          if Decidim::Spid.tenants.map(&:name).include?(tenant_name) || Decidim::Cie.tenants.map(&:name).include?(tenant_name)
            say_status(:conflict, "Esiste già un tenant con questo nome", :red)
            exit
          end
          say_status(:conflict, "Il nome del tenant CIE può contenere solo lettere o underscore.", :red) && exit unless tenant_name.match?(/^[a-z_]+$/)
          template "decidim-cie.rb", "config/initializers/decidim-cie-#{tenant_name}.rb"
        end

        def copy_locale
          copy_file "../../../../../config/idp_list.yml", "config/idp_list.yml" unless File.exists?(Rails.root.join("config/idp_list.yml"))
        end

        def enable_authentication
          secrets_path = Rails.application.root.join("config", "secrets.yml")
          secrets = YAML.safe_load(File.read(secrets_path), [], [], true)

          if secrets.dig("default", "omniauth", "cie")
            say_status :identical, "config/secrets.yml", :blue
          else
            mod = SecretsModifier.new(secrets_path, tenant_name, :cie)
            final = mod.modify

            target_path = Rails.application.root.join("config", "secrets.yml")
            File.open(target_path, "w") { |f| f.puts final }

            say_status :insert, "config/secrets.yml", :green
          end
          say_status :skip, "Ricorda di aggiungere anche a 'production' le configurazioni di omniauth in config/secrets.yml", :yellow
        end

        def locales
          template "cie.en.yml", "config/locales/cie-#{tenant_name}.en.yml"
          say_status :skip, "Completa le traduzione con le lingue disponibili config/locales/cie-#{tenant_name}.en.yml", :yellow
        end

        def organizations
          say_status :skip, "Ricorda di associare le organizzazioni con il relativo tenant in amministrazione", :yellow
        end

        def certificate
          say_status :skip, "Ricorda di generare il certificato e la chiave privata da aggiungere in config/initializers/decidim-cie-#{tenant_name}.rb", :yellow
        end

      end

    end
  end
end