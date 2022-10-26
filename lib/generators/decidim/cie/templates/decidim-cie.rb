# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# frozen_string_literal: true

Decidim::Cie.configure do |config|
  # Definisce il nome del tenant. Solo lettere minuscole e underscores sono permessi.
  # Default: cie. Quando hai multipli tenant devi definire un nome univoco rispetto ai vari tenant.
  config.name = "<%= tenant_name %>"

  # Definisce l'entity ID del service provider:
  # config.sp_entity_id = "https://www.example.org/users/auth/cie/metadata"
  config.sp_entity_id = "<%= entity_id %>"

  # Le chiavi che verranno salvate nell'autorizzazione
  config.metadata_attributes = {
    name: "name",
    surname: "familyName",
    fiscal_code: "fiscalNumber",
    birthday: "dateOfBirth",
  }

  # I campi da escludere dall'export a causa della polocy GDPR.
  # Deve contenere un'array di chiavi presenti in metadata_attributes
  config.export_exclude_attributes = [
    :name, :surname, :fiscal_code
  ]

  # Percorso relativo alla root dell"app della chiave privata
  config.private_key_path = ".keys/private_key.pem"

  # Percorso relativo alla root dell'app del certificato
  config.certificate_path = ".keys/certificate.pem"

  # Percorso relativo alla root dell'app del nuovo certificato
  config.new_certificate_path = nil

  # Livello di crittografia SHA per la generazione delle signature
  config.sha = 256

  # Attribute to match user
  config.uid_attribute = :fiscalNumber

  # Il livello CIE richiesto dall'app
  config.cie_level = 2

  # Link per reindirizzare dopo il login
  config.relay_state = "/"

  # Documentazione https://docs.italia.it/italia/cie/cie-manuale-tecnico-docs/it/master/federazione.html#metadata-sp
  # Configurazioni relative al service provider. it obbligatorio
  config.organization = {
    it: { name: "Nome organizzazione ciao S.p.a", display: "Nome ciao org.", url: "https://www.esempio.com" },
    # en: { name: "Organization name", display: "Org. Name", url: "https://www.example.com" }
  }

  # Documentazione https://docs.italia.it/italia/cie/cie-manuale-tecnico-docs/it/master/federazione.html#metadata-sp
  # Con le informazioni identificative del SP, cui afferisce il proprio referente amministrativo
  # Esempio: {
  #   public: true, ipa_code: "IT12345678901", vat_number: "IT12345678901",
  #   fiscal_code: "XCGBCH47H29H072B", given_name: "SPID Test Team", email: "email@exaple.com",
  #   company: "Nome organizzazione S.p.a", number: "+39061111111",
  #   ateco_code: "62.01", municipality: "H501", province: "RM", country: "IT"
  # }
  config.contact_people_administrative = {
    public: true, ipa_code: "", vat_number: "", fiscal_code: "", given_name: "", email: "", company: "", number: "", ateco_code: "", municipality: "", province: "", country: ""
  }

  # Contenente le informazioni identificative del partner tecnologico, cui afferisce il referente tecnico del SP
  config.contact_people_technical = {}

  # Dati dell'utente richiesti all'identity provider
  config.fields = [
    { name: "name", friendly_name: "Nome", is_required: true },
    { name: "familyName", friendly_name: "Cognome", is_required: true },
    { name: "fiscalNumber", friendly_name: "Codice Fiscale", is_required: true },
    { name: "dateOfBirth", friendly_name: "Data di nascita", is_required: true },
  ]

  #######################################
  # In caso di di metadata esistente e con servizi multupli utilizzare le seguenti configurazioni

  # Per aggiungere più AssertionConsumerService
  # ResponseLocation opzionale
  # config.consumer_services = [
  #   { "Location" => "https://example.org/spid/samlsso", "Binding" => "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" },
  #   { "Location" => "https://example2.org/spid/samlsso", "Binding" => "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" },
  #   { "Location" => "https://example3.org/spid/login", "Binding" => "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" },
  # ]
  # Per aggiungere più SingleLogoutService
  # config.logout_services = [
  #   { "Location" => "https://example.org/spid/samlslo", "Binding" => "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST", "ResponseLocation" => "https://example.org" },
  #   { "Location" => "https://example2.org/spid/samlslo", "Binding" => "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST", "ResponseLocation" => "https://example2.org" },
  #   { "Location" => "https://example3.org/spid/logout", "Binding" => "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" }
  # ]
  #
  # Per customizzare il path del metadata
  # config.metadata_path = "https://example.org/metadata/custom/path"

  # Indicare l'indice dell'array del servizio da utilizzare per questo tenant
  # Default value: 0. Indice per il AssertionConsumerService di default
  # config.default_service_index = 0
  # Default value: 0. Indicare l'indice (dell'array config.consumer_services) per il AssertionConsumerService da utilizzare per questo tenant
  # config.current_consumer_index = 1
  # Default value: 0. Indicare l'indice (dell'array config.attribute_services) per il AttributeConsumingServiceIndex da utilizzare per questo tenant
  # config.current_attribute_index = 0
  # Default value: 0. Indicare l'indice (dell'array config.logout_services) per il SingleLogoutService da utilizzare per questo tenant
  # config.current_logout_index = 0

  # In caso di più AttributeConsumingService
  # Attenzione: l'ordinamento è fondamentale per associare il giusto nome agli attributi specificati in seguito
  # config.attribute_service_names = [ "Nome del servizio 1", "Nome del servizio 2" ]
  # config.attribute_services = [
  #   [
  #     { name: "name", friendly_name: "Nome", is_required: true },
  #     { name: "familyName", friendly_name: "Cognome", is_required: true },
  #     { name: "fiscalNumber", friendly_name: "Codice Fiscale", is_required: true }
  #   ],
  #   [
  #     { name: "name", friendly_name: "Nome", is_required: true },
  #     { name: "familyName", friendly_name: "Cognome", is_required: true },
  #     { name: "fiscalNumber", friendly_name: "Codice Fiscale", is_required: true },
  #     { name: "spidCode", friendly_name: "Codice SPID", is_required: true },
  #     { name: "email", friendly_name: "Email", is_required: true },
  #     { name: "gender", friendly_name: "Genere", is_required: true },
  #     { name: "dateOfBirth", friendly_name: "Data di nascita", is_required: true },
  #     { name: "placeOfBirth", friendly_name: "Luogo di nascita", is_required: true },
  #     { name: "registeredOffice", friendly_name: "registeredOffice", is_required: true },
  #     { name: "ivaCode", friendly_name: "Partita IVA", is_required: true },
  #     { name: "idCard", friendly_name: "ID Carta", is_required: true },
  #     { name: "mobilePhone", friendly_name: "Numero di telefono", is_required: true },
  #     { name: "address", friendly_name: "Indirizzo", is_required: true },
  #     { name: "digitalAddress", friendly_name: "Indirizzo digitale", is_required: true }
  #   ]
  # ]

end