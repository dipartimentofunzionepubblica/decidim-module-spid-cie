# frozen_string_literal: true

Decidim::Cie.configure do |config|
  # Define the name for the tenant. Only lowercase characters and underscores
  # are allowed. If you only have a single AD tenant, you don't need to
  # configure its name. When not configured, it will default to "cie". When you
  # want to connect to multiple tenants, you will need to define a unique name
  # for each tenant.
  config.name = "<%= tenant_name %>"

  # Define the service provider entity ID:
  # config.sp_entity_id = "https://www.example.org/users/auth/cie/metadata/"
  # Or define it in your application configuration and apply it here:
  config.sp_entity_id = "<%= entity_id %>"

  # Configure the SAML attributes that will be stored in the user's
  # authorization metadata.
  config.metadata_attributes = {
    name: "name",
    surname: "familyName",
    fiscal_code: 'fiscalNumber',
    birthday: 'dateOfBirth',
  }

  # Fields to exclude from export due GDPR policy. Array of key from metadata_attributes
  config.export_exclude_attributes = [
    :name, :surname, :fiscal_code
  ]

  # Percorso relativo alla root dell'app della chiave privata
  config.private_key_path = '.keys/private_key.pem'

  # Percorso relativo alla root dell'app del certificato
  config.certificate_path = '.keys/certificate.pem'

  # Percorso relativo alla root dell'app del nuovo certificato
  config.new_certificate_path = nil

  # Livello di crittografia SHA per la generazione delle signature
  config.sha = 256

  # Attribute to match user
  config.uid_attribute = :fiscalNumber

  # Il livello CIE richiesto dall'app
  config.cie_level = 2

  # Link per reindirizzare dopo il login
  config.relay_state = '/'

  # Documentazione https://docs.italia.it/italia/cie/cie-manuale-tecnico-docs/it/master/federazione.html#metadata-sp
  # Configurazioni relative al service provider. it obbligatorio
  config.organization = {
    it: { name: 'Nome organizzazione ciao S.p.a', display: 'Nome ciao org.', url: 'https://www.esempio.com' },
    # en: { name: 'Organization name', display: 'Org. Name', url: 'https://www.example.com' }
  }

  # Documentazione https://docs.italia.it/italia/cie/cie-manuale-tecnico-docs/it/master/federazione.html#metadata-sp
  # Con le informazioni identificative del SP, cui afferisce il proprio referente amministrativo
  config.contact_people_administrative = {
    public: true, ipa_code: 'IT12345678901', vat_number: 'IT12345678901',
    fiscal_code: 'XCGBCH47H29H072B', given_name: 'SPID Test Team', email: 'email@exaple.com',
    company: 'Nome organizzazione S.p.a', number: '+39061111111',
    ateco_code: '62.01', municipality: "H501", province: "RM", country: 'IT'
  }

  # Contenente le informazioni identificative del partner tecnologico, cui afferisce il referente tecnico del SP
  config.contact_people_technical = {}

  config.fields = [
    { name: "name", friendly_name: 'Nome', is_required: true },
    { name: 'familyName', friendly_name: 'Cognome', is_required: true },
    { name: "fiscalNumber", friendly_name: 'Codice Fiscale', is_required: true },
    { name: "dateOfBirth", friendly_name: 'Data di nascita', is_required: true },
  ]
end