# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# frozen_string_literal: true

require 'decidim/spid/token_verifier'

module Decidim
  module Spid
    class Tenant
      include ActiveSupport::Configurable

      # Il nome che identificata il singolo Tenant. Default: spid
      config_accessor :name, instance_writer: false do
        "spid"
      end

      # Definisce l'entity ID del service provider
      config_accessor :sp_entity_id, instance_reader: false do
        ''
      end

      # Certificato in stringa
      config_accessor :certificate, instance_reader: false

      # Chiave privata in stringa
      config_accessor :private_key, instance_reader: false

      # Percorso relativo alla root dell'app del certificato
      config_accessor :certificate_path do
        '.keys/certificate.pem'
      end

      # Percorso relativo alla root dell'app della chiave privata
      config_accessor :private_key_path do
        '.keys/private_key.pem'
      end

      # Percorso relativo alla root dell'app del nuovo certificato
      config_accessor :new_certificate_path do
        nil
      end

      config_accessor :idp_slo_session_destroy do
        proc do |_env, session|
          flash = session["flash"]
          return_to = session["user_return_to"]
          result = session.clear
          session["flash"] = flash if flash
          session["user_return_to"] = return_to if return_to
          result
        end
      end

      # Le chiavi che verranno salvate nell'autorizzazione
      config_accessor :metadata_attributes do
        {}
      end

      # I campi da escludere dall'export a causa della polocy GDPR.
      # Deve contenere un'array di chiavi presenti in metadata_attributes
      config_accessor :export_exclude_attributes do
        []
      end

      # Documentazione https://docs.italia.it/italia/spid/spid-regole-tecniche/it/stabile/metadata.html#service-provider
      # Configurazioni relative al service provider. it obbligatorio
      config_accessor :organization do
        {}
      end

      # Documentazione https://docs.italia.it/italia/spid/spid-regole-tecniche/it/stabile/metadata.html#service-provider
      # Verificare obbligatorietà degli attributi in combinazione tra loro
      config_accessor :contact_people_other do
        {}
      end

      # Documentazione https://docs.italia.it/italia/spid/spid-regole-tecniche/it/stabile/metadata.html#service-provider
      # Verificare obbligatorietà degli attributi in combinazione tra loro
      config_accessor :contact_people_billing do
        {}
      end

      # Dati dell'utente richiesti all'identity provider
      config_accessor :fields do
        {}
      end

      # Permette di customizzare il workflow di autorizzazione.
      config_accessor :workflow_configurator do
        lambda do |workflow|
          # Di default, la scadenza è impostata a 0 minuti e quindi non scadrà
          workflow.expires_in = 0.minutes
        end
      end

      # Permette di customizzare parte del flusso di autenticazione (come
      # le validazioni) prima che l'utente venga autenticato.
      config_accessor :authenticator_class do
        Decidim::Spid::Authentication::Authenticator
      end

      # Permette di customizzare parte del i metadata collezionati dagli
      # attributi SAML.
      config_accessor :metadata_collector_class do
        Decidim::Spid::Verification::MetadataCollector
      end

      # Il livello SPID richiesto dal tenant
      config_accessor :spid_level do
        2
      end

      # Link per reindirizzare dopo il login
      config_accessor :relay_state do
        '/'
      end

      # Livello di crittografia SHA per la generazione delle signature
      config_accessor :sha do
        256
      end

      # Attributo per matchare utente
      config_accessor :uid_attribute do
        :spidCode
      end

      # In caso di di metadata esistente e con servizi multupli utilizzare le seguenti configurazioni
      # ResponseLocation opzionale
      # Per aggiungere più AssertionConsumerService
      config_accessor :consumer_services do
        []
      end

      # Per aggiungere più SingleLogoutService
      config_accessor :logout_services do
        []
      end

      # Per customizzare il path del metadata rispetto al default generato
      config_accessor :metadata_path do
        nil
      end

      # In caso di più AttributeConsumingService
      config_accessor :attribute_services do
        []
      end

      # Per specificare il nome di ogni AttributeConsumingService. Ordinamento fondamentale
      config_accessor :attribute_service_names do
        []
      end

      # Default value: 0. Indice array per il AssertionConsumerService di default
      config_accessor :default_service_index do
        0
      end

      # Default value: 0. Indicare l'indice (dell'array config.consumer_services) per il AssertionConsumerService da utilizzare per questo tenant
      config_accessor :current_consumer_index do
        0
      end

      # Default value: 0. Indicare l'indice (dell'array config.attribute_services) per il AttributeConsumingServiceIndex da utilizzare per questo tenant
      config_accessor :current_attribute_index do
        0
      end

      # Default value: 0. Indicare l'indice (dell'array config.logout_services) per il SingleLogoutService da utilizzare per questo tenant
      config_accessor :current_logout_index do
        0
      end

      # Extra configurazioni
      config_accessor :extra do
      {}
      end

      def initialize
        yield self
      end

      def name=(name)
        raise(InvalidTenantName, "Il nome del tenant SPID può contenere solo lettere o underscore.") unless name.match?(/^[a-z_]+$/)
        config.name = name
      end

      def authenticator_for(organization, oauth_hash)
        authenticator_class.new(self, organization, oauth_hash)
      end

      def metadata_collector_for(saml_attributes)
        metadata_collector_class.new(self, saml_attributes)
      end

      def sp_entity_id
        return config.sp_entity_id if config.sp_entity_id

        "#{application_host}/users/auth/#{config.name}/metadata"
      end

      def certificate
        return File.read(certificate_path) if certificate_path && File.exists?(Rails.root.join(certificate_path))

        config.certificate_path
      end

      def private_key
        return File.read(private_key_path) if private_key_path && File.exists?(Rails.root.join(private_key_path))

        config.private_key_path
      end

      def new_certificate
        return File.read(new_certificate_path) if new_certificate_path && File.exists?(Rails.root.join(new_certificate_path))

        config.new_certificate_path
      end

      def omniauth_settings
        {
          name: name,
          strategy_class: OmniAuth::Strategies::SpidSaml,
          sp_entity_id: sp_entity_id,
          sp_name_qualifier: sp_entity_id,
          idp_slo_session_destroy: idp_slo_session_destroy,
          sp_metadata: {},
          certificate: certificate,
          private_key: private_key,
          new_certificate: new_certificate,
          assertion_consumer_service_url: consumer_services.present? ? nil : "#{sp_entity_id}/users/auth/#{config.name}/callback",
          single_logout_service_url: logout_services.present? ? nil : "#{sp_entity_id}/users/auth/#{config.name}/slo",
          consumer_services: consumer_services,
          logout_services: logout_services,
          attribute_services: attribute_services,
          attribute_service_names: attribute_service_names,
          current_consumer_index: current_consumer_index,
          current_attribute_index: current_attribute_index,
          current_logout_index: current_logout_index,
          config: config,
          skip_recipient_check: consumer_services.present?,
          callback_path: ((consumer_services.present? ? URI(consumer_services[current_consumer_index]['Location']).path : nil) rescue nil),
          logout_path: ((logout_services.present? ? URI(config.logout_services[config.current_consumer_index]['Location']).path : nil) rescue nil),
          metadata_path: metadata_path,
        }.merge(extra)
      end

      def setup!
        setup_routes!

        # Configurazione della strategia SpidSAML OmniAuth per devise
        ::Devise.setup do |config|
          config.omniauth(name.to_sym, omniauth_settings)
        end

        # Customizzazione in caso di fallimenti altrimenti verrebbe sollevata
        # l'eccezione ActionController::InvalidAuthenticityToken.
        devise_failure_app = OmniAuth.config.on_failure
        OmniAuth.config.request_validation_phase = Decidim::Spid::TokenVerifier.new
        OmniAuth.config.on_failure = proc do |env|
          exnovo_metadata = env["PATH_INFO"] && env["PATH_INFO"].match?(%r{^/users/auth/#{config.name}($|/.+)})
          existing_metadata = begin
                                env["PATH_INFO"] &&
                                  [consumer_services[current_consumer_index]["Location"],
                                   logout_services[current_logout_index]["Location"],
                                   metadata_path].map { |a| URI(a).path }.include?(env["PATH_INFO"])
                              rescue
                                false
                              end
          if exnovo_metadata || existing_metadata
            env["devise.mapping"] = ::Devise.mappings[:user]
            Decidim::Spid::OmniauthCallbacksController.action(
              :failure
            ).call(env)
          else
            devise_failure_app.call(env)
          end
        end
      end

      def setup_routes!
        config = self.config
        sso_route = URI(config.consumer_services[config.current_consumer_index]['Location']).path rescue "/users/auth/#{config.name}/callback"
        slo_route = URI(config.logout_services[config.current_consumer_index]['Location']).path rescue "/users/auth/#{config.name}/slo"
        Decidim::Spid::Engine.routes do
          devise_scope :user do
            # Mappatura delle route
            match(
              "/users/auth/#{config.name}",
              to: "omniauth_callbacks#passthru",
              as: "user_#{config.name}_omniauth_authorize",
              via: [:get, :post]
            )

            match(
              sso_route,
              to: "omniauth_callbacks#spid",
              as: "user_#{config.name}_omniauth_callback",
              via: [:get, :post]
            )

            match(
              "/users/auth/#{config.name}/create",
              to: "omniauth_callbacks#create",
              as: "user_#{config.name}_omniauth_create",
              via: [:post, :put, :patch]
            )

            match(
              slo_route,
              to: "sessions#slo",
              as: "user_#{config.name}_omniauth_slo",
              via: [:get, :post]
            )

            match(
              "/users/auth/#{config.name}/spslo",
              to: "sessions#spslo",
              as: "user_#{config.name}_omniauth_spslo",
              via: [:get, :post]
            )
          end
        end
      end

      # Usato per determinare il default service provider entity ID in caso non specificato in sp_entity_id.
      def application_host
        url_options = application_url_options

        host = url_options[:host]
        port = url_options[:port]
        protocol = url_options[:protocol]
        protocol = [80, 3000].include?(port.to_i) ? "http" : "https" if protocol.blank?
        if host.blank?
          host = "localhost"
          port ||= 3000
        end

        return "#{protocol}://#{host}:#{port}" if port && [80, 443].exclude?(port.to_i)

        "#{protocol}://#{host}"
      end

      def application_url_options
        conf = Rails.application.config
        url_options = conf.action_controller.default_url_options
        url_options = conf.action_mailer.default_url_options if !url_options || !url_options[:host]
        url_options || {}
      end
    end
  end
end
