# frozen_string_literal: true

require "decidim/dev"
require "utils/certificate_generator"
require "webmock"

require "utils/runtime"

require "simplecov" if ENV["SIMPLECOV"] || ENV["CODECOV"]
if ENV["CODECOV"]
  require "codecov"
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

ENV["ENGINE_ROOT"] = File.dirname(__dir__)

Decidim::Dev.dummy_app_path = File.expand_path(File.join(__dir__, "decidim_dummy_app"))

require_relative "base_spec_helper"

Decidim::Spid::Test::Runtime.initializer do
  OmniAuth.config.logger = Logger.new("/dev/null")
  Decidim::Spid.configure do |config|
    config.name = "ciao"
    config.sp_entity_id = "http://192.168.1.52/"
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
    config.export_exclude_attributes = [ :name, :surname, :fiscal_code, :company_name, :registered_office, :email, :iva_code ]
    config.private_key_path = '.keys/private_key.pem'
    config.certificate_path = '.keys/certificate.pem'
    config.new_certificate_path = nil
    config.sha = 256
    config.uid_attribute = :spidCode
    config.spid_level = 2
    config.relay_state = '/'
    config.organization = { it: { name: 'Nome organizzazione ciao S.p.a', display: 'Nome ciao org.', url: 'https://www.esempio.com' }}
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

  Decidim::Spid.configure do |config|
    config.name = "spid"
    config.sp_entity_id = "http://localhost:3000/"
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
    config.export_exclude_attributes = [ :name, :surname, :fiscal_code, :company_name, :registered_office, :email, :iva_code ]
    config.private_key_path = '.keys/private_key.pem'
    config.certificate_path = '.keys/certificate.pem'
    # config.new_certificate_path = '.keys/new_certificate.pem'
    config.sha = 256
    # config.uid_attribute = :spidCode
    # config.spid_level = 2
    config.relay_state = "/"
    config.organization = { it: { name: 'Nome organizzazione test S.p.a', display: 'Nome test org.', url: 'https://www.esempio.com' } }
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
      { name: "email", friendly_name: 'Email', is_required: true },
      { name: "spidCode", friendly_name: 'Codice SPID', is_required: true }
    ]
  end
end

Decidim::Spid::Test::Runtime.load_app

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request

  config.before(:each, type: :request) do
    host! Decidim::Spid.tenants.first.config[:sp_entity_id]
  end
end
