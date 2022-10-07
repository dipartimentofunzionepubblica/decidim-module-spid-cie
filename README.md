# Decidim SPID & CIE
Autenticazione SPID & CIE per Decidim v0.25.2. Questa gemma si appoggia: [ruby-saml](https://github.com/onelogin/ruby-saml), [decidim](https://github.com/decidim/decidim/tree/v0.24.3) e [omniauth](https://github.com/omniauth/omniauth).

Ispirata a [decidim-msad](https://github.com/mainio/decidim-module-msad). Gemma sviluppata da [Kapusons](https://www.kapusons.it)

## Usage
How to use my plugin.

## Installazione
Aggiungi al tuo Gemfile

```ruby
gem 'decidim-spid'
```

ed esegui dal terminale
```bash
$ bundle install
$ rails generate decidim:spid:install TENANT_NAME ENTITY_ID
$ rails generate decidim:cie:install TENANT_NAME ENTITY_ID
# Ripetere l'installer per ogni tenant di cui si ha bisogno.
```
Sostituisti TENANT_NAME con una stringa univoca che identificato il tenant e ENTITY_ID con un identificativo (URI) univoco dell'entità SPID
Il TENANT_NAME deve essere univoco anche tra SPID e CIE.

Verranno generati:
1. `config/initializers/decidim-spid-#{tenant_name}.rb` per configurare lo SPID ad ogni installazione.
2. `config/initializers/decidim-cie-#{tenant_name}.rb` per configurare lo CIE ad ogni installazione.
3. `config/idp_list.yml` con la lista dei provider per ogni environment.
4. verrà automaticamente aggiunto in `config/secrets.yml` nel blocco default la configurazione `omniauth` necessaria. Aggiungere la configurazione ai vari environment a seconda delle esigenze.
5. `config/locales/spid-#{tenant_name}.en.yml` con le etichette necessarie. Duplicare per ogni locale necessaria.

## Configurazione
Associare in amministrazione il `tenant_name` ad ogni organizzazione sia per SPID che per CIE.
Completare le configurazioni nell'`initializer` di ogni tenant.

```ruby
# config/initializers/decidim-spid-#{tenant_name}.rb
Decidim::Spid.configure do |config|
  #config ...
end

# config/initializers/decidim-cie-#{tenant_name}.rb
Decidim::Cie.configure do |config|
  #config ...
end
```
tramite il quale potete accedere alle seguenti configurazioni:

|Nome|Valore di default|Descrizione|Obbligatorio|
|:---|:---|:---|:---|
|config.name|`'#{tenant_name}'`|Identifivativo univoco di ogni tenant. Compilato automaticamente dall'installer|✓|
|config.sp_entity_id|`'#{entity_id}'`|Identificativo univoco (URI) dell'entità SPID|✓|
|config.metadata_attributes|`{ name: "name", surname: "familyName", fiscal_code: 'fiscalNumber', gender: 'gender', birthday: 'dateOfBirth', birthplace: "placeOfBirth", company_name: "companyName", registered_office: "registeredOffice", iva_code: "ivaCode", id_card: 'idCard', mobile_phone: 'mobilePhone', email: 'email', address: 'address', digital_address: 'digitalAddress' }`|Attibuti che verranno salvati all'autenticazione con relativo mapping||
|config.export_exclude_attributes|`'[ :name, :surname, :fiscal_code, :company_name, :registered_office, :email, :iva_code ]'`|In amministrazione viene aggiunta la funzionalità di export per ogni processo. Questo attributo permette di escludere i campi nell'export per il GDPR.||
|config.private_key_path|`.keys/private_key.pem`|Percorso relativo alla root dell'app della chiave privata|✓|
|config.certificate_path|`.keys/certificate.pem`|Percorso relativo alla root dell'app del certificato. La data di scadenza verrà visualizzata in amministrazione una volta associato con il tenant_name.|✓|
|config.new_certificate_path|`nil`|Percorso relativo alla root dell'app del nuovo certificato in caso di sostituzione. La data di scadenza verrà visualizzata in amministrazione una volta associato con il tenant_name.||
|config.sha|`256`|Livello di crittografia SHA per la generazione delle signature||
|config.uid_attribute|`:spidCode`|Attributo da utilizzare come identificato in omniauth||
|config.spid_level|`2`|Il livello SPID richiesto dal tenant||
|config.relay_state|`/`|Link per reindirizzare dopo il login||
|config.organization|`{ it: { name: 'Nome organizzazione S.p.a', display: 'Nome org.', url: 'https://www.esempio.com' } }`|Configurazioni relative al service providere. Documentazione: https://docs.italia.it/italia/spid/spid-regole-tecniche/it/stabile/metadata.html#service-provider|✓|
|config.contact_people_other|`{ public: true, ipa_code: 'IT12345678901', vat_number: 'IT12345678901', fiscal_code: 'XCGBCH47H29H072B', given_name: 'SPID Test Team', email: 'email@exaple.com', company: 'Nome organizzazione S.p.a', number: '+39061111111', givenName: "Name" }`|Configurazioni relative al service providere. Documentazione: https://docs.italia.it/italia/spid/spid-regole-tecniche/it/stabile/metadata.html#service-provider|✓|
|config.contact_people_billing|`{}`|Configurazioni relative al service provider (privato). Documentazione: https://docs.italia.it/italia/spid/spid-regole-tecniche/it/stabile/metadata.html#service-provider||
|config.fields|`[ { name: "name", friendly_name: 'Nome', is_required: true }, { name: 'familyName', friendly_name: 'Cognome', is_required: true }, { name: "fiscalNumber", friendly_name: 'Codice Fiscale', is_required: true }, { name: "email", friendly_name: 'Email', is_required: true }]`|Attributi richiesti all'Identity Provider. Configurazioni relative al service providere. Documentazione: https://docs.italia.it/italia/spid/spid-regole-tecniche/it/stabile/metadata.html#service-provider|✓|

### URLs
```bash

Routes for Decidim::Spid::Engine:
                       destroy_user_session DELETE|POST    /users/sign_out(.:format)                     decidim/spid/sessions#destroy
                  slo_callback_user_session GET            /users/slo_callback(.:format)                 decidim/spid/sessions#slo_callback
     user_#{tenant_name}_omniauth_authorize GET|POST       /users/auth/#{tenant_name}(.:format)          decidim/spid/omniauth_callbacks#passthru
      user_#{tenant_name}_omniauth_callback GET|POST       /users/auth/#{tenant_name}/callback(.:format) decidim/#{tenant_name}/omniauth_callbacks#spid
        user_#{tenant_name}_omniauth_create POST|PUT|PATCH /users/auth/#{tenant_name}/create(.:format)   decidim/spid/omniauth_callbacks#create
           user_#{tenant_name}_omniauth_slo GET|POST       /users/auth/#{tenant_name}/slo(.:format)      decidim/spid/sessions#slo
         user_#{tenant_name}_omniauth_spslo GET|POST       /users/auth/#{tenant_name}/spslo(.:format)    decidim/spid/sessions#spslo

Routes for Decidim::Cie::Engine:
                       destroy_user_session DELETE|POST    /users/sign_out(.:format)                     decidim/cie/sessions#destroy
                  slo_callback_user_session GET            /users/slo_callback(.:format)                 decidim/cie/sessions#slo_callback
     user_#{tenant_name}_omniauth_authorize GET|POST       /users/auth/#{tenant_name}(.:format)          decidim/cie/omniauth_callbacks#passthru
      user_#{tenant_name}_omniauth_callback GET|POST       /users/auth/#{tenant_name}/callback(.:format) decidim/cie/omniauth_callbacks#cie
        user_#{tenant_name}_omniauth_create POST|PUT|PATCH /users/auth/#{tenant_name}/create(.:format)   decidim/cie/omniauth_callbacks#create
           user_#{tenant_name}_omniauth_slo GET|POST       /users/auth/#{tenant_name}/slo(.:format)      decidim/cie/sessions#slo
         user_#{tenant_name}_omniauth_spslo GET|POST       /users/auth/#{tenant_name}/spslo(.:format)    decidim/cie/sessions#spslo

Routes for Decidim::Spid::Verification::Engine:
                          new_authorization GET           /authorizations/new(.:format)                   decidim/spid/verification/authorizations#new
                                       root GET           /                                               decidim/spid/verification/authorizations#new

Routes for Decidim::Cie::Verification::Engine:
                          new_authorization GET           /authorizations/new(.:format)                   decidim/cie/verification/authorizations#new
                                       root GET           /                                               decidim/cie/verification/authorizations#new
                  
Routes for Decidim::Spid::AdminEngine:
                                    exports GET           /admin/spid/exports(.:format)                   decidim/spid/admin/exports#index

```

### Views
I button "Entra con CIE" e "Entra con SPID" automaticamente verrànno visualizzati nella pagina di login se l'autenticazione viene abilitata dall'amministrazione.
Per renderizzare il button predefinito:

```ruby
<%= render partial: 'spid/spid', locals: { size: :m } %>
# size deve essere in [ :s, :m, :l, :xl]. Default: :m. Configurabile dell'amministrazione per ogni tenant.

<%= render partial: 'cie/cie', locals: { size: :m } %>
# size deve essere in [ :s, :m, :l, :xl]. Default: :m. Configurabile dell'amministrazione per ogni tenant.
```
Altrimenti è possibile customizzare la view creando il file app/views/decidim/spid/_spid.html.erb e app/views/decidim/cie/_cie.html.erb.

### Ulteriori info
* Una volta associato un'utente esistente ad un utenza SPID o CIE viene inibita la classica autenticazione con email e password ed il recupera password.
* Il login con SPID o CIE si integra con la registrazione integrativa di decidim presentanto la form di registrazione qualora i dati utenti non soddisfino le validazioni di registarzione.
* L'utente invitato ad un processo privato viene forzato ad loggarsi con SPID o CIE.
* Viene tenuta traccia delle operazioni di login, logout e registrazioni tramite SPID o CIE e possono essere visualizzate Admin Activity log.
* In amministrazione, gli utenti che hanno effettuato registrazione o login (per utenti esistenti) sono identificati con un badge relativamente per SPID o CIE. Inoltre è possibile filtrare gli utenti che hanno associato l'utenza SPID o CIE.

## Contributing
https://github.com/kapusons/decidim-module-spid/graphs/contributors

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).