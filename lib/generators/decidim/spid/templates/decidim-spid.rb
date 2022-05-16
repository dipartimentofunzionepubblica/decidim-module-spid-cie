# frozen_string_literal: true

Decidim::Spid.configure do |config|
  # Define the name for the tenant. Only lowercase characters and underscores
  # are allowed. If you only have a single AD tenant, you don't need to
  # configure its name. When not configured, it will default to "spid". When you
  # want to connect to multiple tenants, you will need to define a unique name
  # for each tenant.
  config.name = "<%= tenant_name %>"

  # Define the service provider entity ID:
  # config.sp_entity_id = "https://www.example.org/users/auth/spid/metadata/"
  # Or define it in your application configuration and apply it here:
  config.sp_entity_id = "<%= entity_id %>"

  # Configure the SAML attributes that will be stored in the user's
  # authorization metadata.
  config.metadata_attributes = {
    name: "name",
    surname: "familyName",
    fiscal_code: 'fiscalNumber',
    gender: 'gender',
    birthday: 'dateOfBirth',
    birthplace: "placeOfBirth",
    company_name: "companyName",
    registered_office: "registeredOffice",
    iva_code: "ivaCode",
    id_card: 'idCard',
    mobile_phone: 'mobilePhone',
    email: 'email',
    address: 'address',
    digital_address: 'digitalAddress'
  }

  # Fields to exclude from export due GDPR policy. Array of key from metadata_attributes
  config.export_exclude_attributes = [
    :name, :surname, :fiscal_code, :company_name, :registered_office, :email, :iva_code
  ]

  # Percorso relativo alla root dell'app della chiave privata
  config.private_key_path = '.keys/private_key.pem'

  # Percorso relativo alla root dell'app del certificato
  config.certificate_path = '.keys/certificate.pem'

  # Percorso relativo alla root dell'app del nuovo certificato
  config.new_certificate_path = '.keys/new_certificate.pem'

  # Livello di crittografia SHA per la generazione delle signature
  config.sha = 256

  # Attribute to match user
  config.uid_attribute = :spidCode

  # Il livello SPID richiesto dall'app
  config.spid_level = 2

  # Link per reindirizzare dopo il login
  config.relay_state = '/'

  # Documentazione https://docs.italia.it/italia/spid/spid-regole-tecniche/it/stabile/metadata.html#service-provider
  # Configurazioni relative al service provider. it obbligatorio
  config.organization = {
    it: { name: 'Nome organizzazione ciao S.p.a', display: 'Nome ciao org.', url: 'https://www.esempio.com' },
    # en: { name: 'Organization name', display: 'Org. Name', url: 'https://www.example.com' }
  }

  # Documentazione https://docs.italia.it/italia/spid/spid-regole-tecniche/it/stabile/metadata.html#service-provider
  # Verificare obbligatorietà degli attributi in combinazione tra loro
  config.contact_people_other = {
    public: true, ipa_code: 'IT12345678901', vat_number: 'IT12345678901',
    fiscal_code: 'XCGBCH47H29H072B', given_name: 'SPID Test Team', email: 'email@exaple.com',
    company: 'Nome organizzazione S.p.a', number: '+39061111111', givenName: "Name"
  }

  # Obbligatorio solo per soggetti privati
  config.contact_people_billing = {}

  config.fields = [
    { name: "name", friendly_name: 'Nome', is_required: true },
    { name: 'familyName', friendly_name: 'Cognome', is_required: true },
    { name: "fiscalNumber", friendly_name: 'Codice Fiscale', is_required: true },
    { name: "spidCode", friendly_name: 'Codice SPID', is_required: true },
    { name: "email", friendly_name: 'Email', is_required: true },
    { name: "gender", friendly_name: 'Genere', is_required: true },
    { name: "dateOfBirth", friendly_name: 'Data di nascita', is_required: true },
    { name: "placeOfBirth", friendly_name: 'Luogo di nascita', is_required: true },
    { name: "registeredOffice", friendly_name: 'registeredOffice', is_required: true },
    { name: "ivaCode", friendly_name: 'Partita IVA', is_required: true },
    { name: "idCard", friendly_name: 'ID Carta', is_required: true },
    { name: "mobilePhone", friendly_name: 'Numero di telefono', is_required: true },
    { name: "address", friendly_name: 'Indirizzo', is_required: true },
    { name: "digitalAddress", friendly_name: 'Indirizzo digitale', is_required: true }
  ]
end