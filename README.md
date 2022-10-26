# Decidim SPID & CIE
Autenticazione SPID & CIE per Decidim v0.25.2. Questa gemma si appoggia: [ruby-saml](https://github.com/onelogin/ruby-saml), [decidim](https://github.com/decidim/decidim/tree/v0.25.2) e [omniauth](https://github.com/omniauth/omniauth).

Ispirata a [decidim-msad](https://github.com/mainio/decidim-module-msad).

## Installazione
Aggiungi al tuo Gemfile

```ruby
gem 'decidim-spid-cie'
```

ed esegui dal terminale
```bash
$ bundle install
$ rails generate decidim:spid:install TENANT_NAME ENTITY_ID
$ rails generate decidim:cie:install TENANT_NAME ENTITY_ID
# Ripetere l'installer per ogni tenant di cui si ha bisogno.
```
Sostituisti TENANT_NAME con una stringa univoca che identifica il tenant e ENTITY_ID con un identificativo (URI) univoco dell'entità SPID.
Il TENANT_NAME deve essere univoco anche tra SPID e CIE.

Verranno generati:
1. `config/initializers/decidim-spid-#{tenant_name}.rb` per configurare SPID ad ogni installazione.
2. `config/initializers/decidim-cie-#{tenant_name}.rb` per configurare CIE ad ogni installazione.
3. `config/idp_list.yml` contiene la lista degli identity provider per ogni environment.
4. verrà automaticamente aggiunto in `config/secrets.yml` nel blocco default la configurazione `omniauth` necessaria. Aggiungere la configurazione ai vari environment a seconda delle esigenze.
5. `config/locales/spid-#{tenant_name}.en.yml` con le etichette necessarie. Duplicare per ogni locale necessaria.

La lista degli identity provider è presente alla pagina https://registry.spid.gov.it/identity-providers. Qualora dovessero subire modifiche bisogna aggiornare il file `config/idp_list.yml` con le relative modifiche.
Sono presenti nel blocco development anche gli endpoint di default che il pacchetto [spid-saml-check](https://github.com/italia/spid-saml-check) utilizza. Il pacchetto è utile per i test di validazione del metadata, request e response SAML.

Per modificare o eliminare un tenant è sufficiente modificare o cancellare proprio il file generato in initializers e fare un restart del server.
Qualora si voglia eliminare la gemma è sufficiente eliminare o ripristinare i file generati degli step precedenti.

## Configurazione
Associare nel pannello di amministratore di sistema (/system) il `tenant_name` ad ogni organizzazione sia per SPID che per CIE.
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
|config.export_exclude_attributes|`'[ :name, :surname, :fiscal_code, :company_name, :registered_office, :email, :iva_code ]'`|Nel pannello di amministratore di sistema (/system) viene aggiunta la funzionalità di export per ogni processo. Questo attributo permette di escludere i campi nell'export per il GDPR.||
|config.private_key_path|`.keys/private_key.pem`|Percorso relativo alla root dell'app della chiave privata|✓|
|config.certificate_path|`.keys/certificate.pem`|Percorso relativo alla root dell'app del certificato. La data di scadenza verrà visualizzata nel pannello di amministratore di sistema (/system) una volta associato con il tenant_name.|✓|
|config.new_certificate_path|`nil`|Percorso relativo alla root dell'app del nuovo certificato in caso di sostituzione. La data di scadenza verrà visualizzata nel pannello di amministratore di sistema (/system) una volta associato con il tenant_name.||
|config.sha|`256`|Livello di crittografia SHA per la generazione delle signature||
|config.uid_attribute|`:spidCode`|Attributo da utilizzare come identificato in omniauth||
|config.spid_level|`2`|Il livello SPID richiesto dal tenant||
|config.relay_state|`/`|Link per reindirizzare dopo il login||
|config.organization|`{ it: { name: 'Nome organizzazione S.p.a', display: 'Nome org.', url: 'https://www.esempio.com' } }`|Configurazioni relative al service providere. Documentazione: https://docs.italia.it/italia/spid/spid-regole-tecniche/it/stabile/metadata.html#service-provider|✓|
|config.contact_people_other|`{ public: true, ipa_code: 'IT12345678901', vat_number: 'IT12345678901', fiscal_code: 'XCGBCH47H29H072B', given_name: 'SPID Test Team', email: 'email@exaple.com', company: 'Nome organizzazione S.p.a', number: '+39061111111', givenName: "Name" }`|Configurazioni relative al service providere. Documentazione: https://docs.italia.it/italia/spid/spid-regole-tecniche/it/stabile/metadata.html#service-provider|✓|
|config.contact_people_billing|`{}`|Configurazioni relative al service provider (privato). Documentazione: https://docs.italia.it/italia/spid/spid-regole-tecniche/it/stabile/metadata.html#service-provider||
|config.fields|`[ { name: "name", friendly_name: 'Nome', is_required: true }, { name: 'familyName', friendly_name: 'Cognome', is_required: true }, { name: "fiscalNumber", friendly_name: 'Codice Fiscale', is_required: true }, { name: "email", friendly_name: 'Email', is_required: true }]`|Attributi richiesti all'Identity Provider. Configurazioni relative al service providere. Documentazione: https://docs.italia.it/italia/spid/spid-regole-tecniche/it/stabile/metadata.html#service-provider|✓|

### URLs
Il metadata se non diversamente specificato in `config.metadata_path` viene esposto `/users/auth/#{tenant_name}/metadata`.

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
I button "Entra con CIE" e "Entra con SPID" automaticamente verrànno visualizzati nella pagina di login se l'autenticazione viene abilitata nel pannello di amministratore di sistema (/system).
Per renderizzare il button predefinito:

```ruby
<%= render partial: 'spid/spid', locals: { size: :m } %>
# button_size deve essere in [ :s, :m, :l, :xl]. Default: :m. Configurabile nel pannello di amministratore di sistema (/system) per ogni tenant.

<%= render partial: 'cie/cie', locals: { size: :m } %>
# button_size deve essere in [ :s, :m, :l, :xl]. Default: :m. Configurabile nel pannello di amministratore di sistema (/system) per ogni tenant.
```
Altrimenti è possibile customizzare la view creando il file app/views/decidim/spid/_spid.html.erb e app/views/decidim/cie/_cie.html.erb.

### Aggiornamento certificati
Per aggiornare il certificato del service provider senza interruzione del servizio, può essere utilizzato il parametro `new_certificate_path`. 
Questo pubblicherà il nuovo certificato nel metadata in modo che gli Identity Provider possano cachere il certificato.

Per esempio, se vuoi passare dal `CERT A` al `CERT B`, prima di sostituirlo le tue configurazioni dovrebbero essere come le seguenti.
Entrambi `CERT A` e `CERT B` compariranno nel SP metadata, e `CERT A` verrà utilizzato per firmare.

```ruby
  config.certificate_path = "CERT A"
  config.private_key_path = "PRIVATE KEY FOR CERT A"
  config.new_certificate_path = "CERT B"
```

Dopo che gli IdP avranno messo in cache `CERT B`, potrai aggiornare le configurazioni come di seguito:

```ruby
  config.certificate_path = "CERT B"
  config.private_key_path = "PRIVATE KEY FOR CERT B"
```

### Ulteriori informazioni
* Una volta associato un'utente esistente ad un utenza SPID o CIE viene inibita la classica autenticazione con email e password ed il recupera password.
* Il login con SPID o CIE si integra con la registrazione integrativa di decidim presentanto la form di registrazione qualora i dati utenti non soddisfino le validazioni di registarzione.
* L'utente invitato ad un processo privato viene forzato ad loggarsi con SPID o CIE.
* Viene tenuta traccia delle operazioni di login, logout e registrazioni tramite SPID o CIE e possono essere visualizzate Admin Activity log.
* In amministrazione, gli utenti che hanno effettuato registrazione o login (per utenti esistenti) sono identificati con un badge relativamente per SPID o CIE. Inoltre è possibile filtrare gli utenti che hanno associato l'utenza SPID o CIE.

## Configurazione in caso di servizi multipli
In caso si ha la necissità di specificare più `AssertionConsumerService`, `SingleLogoutService` e `AttributeConsumingService` bisogna completare le seguenti configurazioni ed ignorare `config.fields`:

|Nome|Valore di default|Descrizione|Obbligatorio|
|:---|:---|:---|:---|
|config.consumer_services|`[]`|Dettaglio AssertionConsumerService: Esempio: `config.consumer_services = [{ 'Location' => 'https://example.org/spid/samlsso', 'ResponseLocation' => 'https://example.org', 'Binding' => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect' }, ...]` |✓|
|config.logout_services|`[]`|Dettaglio SingleLogoutService: Esempio: `config.logout_services = [ { 'Location' => 'https://example.org/spid/samlslo', 'Binding' => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST' }, ... ]`|✓|
|config.metadata_path|`nil`|Per personalizzare l'url del metadata. Esempio: `config.metadata_path = "https://example.org/metadata/custom/path"`|✓|
|config.default_service_index|`0`|Indicare l'indice dell'array (`config.consumer_services`) per specificare il servizio di default. |✓|
|config.current_consumer_index|`0`|Indicare l'indice (dell'array `config.consumer_services`) per il AssertionConsumerService da utilizzare per questo tenant|✓|
|config.current_attribute_index|`0`|Indicare l'indice (dell'array config.attribute_services) per il AttributeConsumingServiceIndex da utilizzare per questo tenant|✓|
|config.current_logout_index|`0`|Indicare l'indice (dell'array `config.logout_services`) per il SingleLogoutService da utilizzare per questo tenant|✓|
|config.attribute_services|`[]`|Indicare AttributeConsumingService per ogni servizio.  Esempio: `config.attribute_services = [ [ { name: "name", friendly_name: 'Nome', is_required: true }, { name: 'familyName', friendly_name: 'Cognome', is_required: true }, ...], ...]` Per ulteriori dettagli vedere `config.fields`.|✓|
|config.attribute_service_names|`[]`|Indicare il nome AttributeConsumingService per ogni servizio.  Esempio: `config.attribute_service_names = [ "Nome del servizio 1", "Nome del servizio 2"]` Attenzione: l'ordinamento è fondamentale per associare correttamente gli `config.attribute_services`.|✓|

## Contributori
Gemma sviluppata da [Formez PA](https://www.formez.it) e da [Kapusons](https://www.kapusons.it). Per contatti scrivere a maintainer-partecipa@formez.it.

## Licenza
Vedi [LICENSE-AGPLv3.txt](LICENSE-AGPLv3.txt).