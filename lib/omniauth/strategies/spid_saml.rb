# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

require "omniauth-saml"
require 'decidim/spid_cie/loader'

# Strategia SPID SAML personalizzata secondo le configurazioni nell'initializer

module OmniAuth
  module Strategies
    class SpidSaml < SAML

      def initialize(app, *args, &block)
        super
        # Decidim::Spid::Utils.current_name = options[:name]
        options[:sp_name_qualifier] = options[:sp_entity_id] if options[:sp_name_qualifier].nil?
        options[:issuer] = options[:sp_entity_id]

        [
          :idp_name_qualifier,
          :name_identifier_format,
          :security
        ].each do |key|
          options.delete(key) if options[key].nil?
        end

        tenant = Decidim::Spid.find_tenant(options[:name])
        @options = OmniAuth::Strategy::Options.new(options.merge(tenant ? tenant.config : {}))
      end

      RUBYSAML_RESPONSE_OPTIONS = OneLogin::RubySaml::Response::AVAILABLE_OPTIONS

      option :name_identifier_format, nil
      option :idp_sso_service_url_runtime_params, {}
      option :request_attributes, [
        { :name => 'email', :name_format => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', :friendly_name => 'Email address' },
        { :name => 'name', :name_format => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', :friendly_name => 'Full name' },
        { :name => 'first_name', :name_format => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', :friendly_name => 'Given name' },
        { :name => 'last_name', :name_format => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', :friendly_name => 'Family name' }
      ]
      option :attribute_service_name, "Required attributes"
      option :attribute_statements, {
        name: ["name"],
        email: ["email", "mail"],
        first_name: ["first_name", "firstname", "firstName"],
        last_name: ["last_name", "lastname", "lastName"]
      }
      option :slo_default_relay_state
      option :uid_attribute
      option :idp_slo_session_destroy, proc { |_env, session| session.clear }

      def request_phase
        authn_request = Decidim::SpidCie::Authrequest.new

        with_auth_settings do |settings|
          session[:"tenant-spid-name"] = options["name"]
          session[:"#{options["name"]}-params"] = request.params.dig("sso").merge(issue_instant: authn_request.issue_instant, uuid: authn_request.uuid)
          redirect_to(authn_request.create(settings, additional_params_for_authn_request.merge('RelayState' => Base64.strict_encode64(session['omniauth.origin'] || '/'))))
        end
      end

      def callback_phase
        raise OneLogin::RubySaml::ValidationError.new("SAML response missing") unless request.params["SAMLResponse"]
        with_auth_settings do |settings|
          handle_response(request.params["SAMLResponse"], options_for_response_object, settings) do
            env['omniauth.auth'] = auth_hash
            call_app!
          end
        end
      rescue OneLogin::RubySaml::ValidationError
        fail!(:invalid_ticket, $!)
      end

      def other_phase
        if request_path_pattern.match(current_path) || custom_path_pattern_matches?(current_path)
          @env['omniauth.strategy'] ||= self
          setup_phase

          if (on_subpath?(:metadata) || on_custom_metadata) && match_current_organization?
            other_phase_for_metadata
          elsif on_subpath?(:slo) || on_custom_slo?(:slo)
            other_phase_for_slo
          elsif on_subpath?(:spslo)
            other_phase_for_spslo
          else
            call_app!
          end
        else
          call_app!
        end
      end

      def custom_path_pattern_matches?(current_path)
        begin
          URI(options["consumer_services"][options["current_consumer_index"]]['Location']).path == current_path ||
            URI(options["logout_services"][options["current_logout_index"]]['Location']).path == current_path ||
            URI(options["metadata_path"]).path == current_path ||
            URI(options["logout_services"][options["current_logout_index"]]['ResponseLocation']).path == current_path
        rescue
          options["metadata_path"].presence ? (URI(options["metadata_path"]).path == current_path) : false
        end
      end

      def on_custom_slo?(subpath)
        logout_path == current_path || (response_path == current_path && request.params["SAMLResponse"].present?)
      end

      def on_custom_metadata
        metadata_path == current_path
      end

      def match_current_organization?
        begin
          request.env["decidim.current_organization"].enabled_omniauth_providers.dig(:spid, :tenant_name) == options[:name]
        rescue
          false
        end
      end

      uid do
        if options.uid_attribute
          ret = find_attribute_by([options.uid_attribute])
          if ret.nil?
            raise OneLogin::RubySaml::ValidationError.new("SAML response missing '#{options.uid_attribute}' attribute")
          end
          ret
        else
          @name_id
        end
      end

      info do
        found_attributes = options.attribute_statements.map do |key, values|
          attribute = find_attribute_by(values)
          [key, attribute]
        end

        Hash[found_attributes]
      end

      # extra { { :raw_info => @attributes.attributes, :session_index => @session_index, :response_object =>  @response_object } }
      extra { { :raw_info => @attributes } }

      def find_attribute_by(keys)
        keys.each do |key|
          return @attributes[key] if @attributes && @attributes[key]
        end

        nil
      end

      def response_object
        return nil unless request.params["SAMLResponse"]

        with_settings do |settings|
          response = OneLogin::RubySaml::Response.new(
            request.params["SAMLResponse"],
            options_for_response_object.merge(settings: settings)
          )
          response
        end
      end

      private

      def request_path_pattern
        @request_path_pattern ||= %r{\A#{Regexp.quote(request_path)}(/|\z)}
      end

      def on_subpath?(subpath)
        on_path?("#{request_path}/#{subpath}")
      end

      def handle_response(raw_response, opts, settings)
        response = Decidim::SpidCie::Response.new(raw_response, opts.merge(settings: settings), session[:"#{options["name"]}-params"])
        valid = response.is_valid?(true)
        if valid

          @name_id = response.name_id.try(:strip)
          session[:"#{options["name"]}-uid"] = response.attributes[options.uid_attribute] || @name_id
          session[:"#{options["name"]}-index"] = response.sessionindex
          @attributes = response.attributes
          yield if block_given?
        else
          matches = nil
          if response.errors && response.errors.any? { |a| matches = a.match(/The status code of the Response was not Success, was Responder => AuthnFailed -> ErrorCode nr(19|2[0-5])/) } && (error_code = matches.try(:[], 1)).present?
            msg = "decidim.spid.sso_request.failure_#{error_code}"
          else
            if !Rails.env.development?
              msg = 'decidim.spid.sso_request.failure'
            else
              msg = response.errors.try(:first)
            end
          end
          raise OneLogin::RubySaml::ValidationError.new(msg)
        end

      end

      def response_fingerprint
        return nil unless request.params["SAMLResponse"]
        response = request.params["SAMLResponse"]
        response = (response =~ /^</) ? response : Base64.decode64(response)
        document = XMLSecurity::SignedDocument::new(response)
        cert_element = REXML::XPath.first(document, "//ds:X509Certificate", { "ds" => 'http://www.w3.org/2000/09/xmldsig#' })
        base64_cert = cert_element.text
        cert_text = Base64.decode64(base64_cert)
        cert = OpenSSL::X509::Certificate.new(cert_text)
        Digest::SHA1.hexdigest(cert.to_der).upcase.scan(/../).join(':')
      rescue
        nil
      end

      def current_idp
        request.params.try(:[], 'sso').try(:[], 'idp') || session[:"#{options["name"]}-params"].try(:[], 'idp')
      end

      def idp_options
        idp = Decidim::SpidCie::Idp.find_spid(current_idp)
        idp_metadata_parser = ::OneLogin::RubySaml::IdpMetadataParser.new

        if options.idp_metadata_file
          return idp_metadata_parser.parse_to_hash(
            File.read(options.idp_metadata_file)
          )
        end

        begin
          idp_metadata_parser.parse_remote_to_hash(
            idp.metadata_url,
            !Rails.env.development?
          )
        rescue ::URI::InvalidURIError
          {}
        end
      end

      def authn_options
        s = {}
        s[:authn_context] = "https://www.spid.gov.it/SpidL#{options.spid_level}"
        s[:authn_context_comparison] = 'minimum'
        s[:force_authn] = options.spid_level != 1
        s[:protocol_binding] = 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST'
        s[:relay_state] = options.relay_state
        s[:current_consumer_index] = options.current_consumer_index
        s[:current_attribute_index] = options.current_attribute_index

        s[:idp_cert_fingerprint] = response_fingerprint

        idp_options.merge(s)
      end

      def metadata_options
        options.attribute_services ? {
          attribute_services: options.attribute_services
        } : {}
      end

      def with_auth_settings
        yield Decidim::SpidCie::Settings.new(options.merge(authn_options))
      end

      def with_metadata_settings
        yield Decidim::SpidCie::Settings.new(options.merge(metadata_options))
      end

      def with_settings
        yield Decidim::SpidCie::Settings.new(options)
      end

      def logout_url
        full_host + logout_path + query_string
      end

      def logout_path
        logout_path ||= begin
                          path = options[:logout_path] if options[:logout_path].is_a?(String)
                          path ||= current_path if options[:logout_path].respond_to?(:call) && options[:logout_path].call(env)
                          path ||= custom_path(:logout_path)
                          path ||= "#{script_name}#{path_prefix}/#{name}/slo"
                          path
                        end
      end

      def response_path
        response_path ||= URI(options["logout_services"][options["current_logout_index"]]['ResponseLocation']).path rescue nil
      end

      def metadata_path
        metadata_path ||= begin
                            path = URI(options[:metadata_path]).path if options[:metadata_path].is_a?(String)
                            path ||= current_path if options[:metadata_path].respond_to?(:call) && options[:metadata_path].call(env)
                            path ||= "#{script_name}#{path_prefix}/#{name}/metadata"
                            path
                          end
      end

      def other_phase_for_metadata
        with_metadata_settings do |settings|
          response = Decidim::SpidCie::Metadata.new
          Rack::Response.new(
            response.generate(settings),
            200,
            "Content-Type" => "application/xml"
          ).finish
        end
      end

      def other_phase_for_slo
        path = request.params["RelayState"] rescue options["relay_state"]
        with_auth_settings do |settings|
          logout_response = ::Decidim::SpidCie::Logoutresponse.new(request.params["SAMLResponse"], settings, matches_request_id: session["saml_transaction_id"])

          logout_response.soft = false

          if valid = logout_response.validate
            session.delete("tenant-spid-name")
            session.delete("spid-uid")
            session.delete("spid-index")
            session.delete("spid-params")
            session.delete("saml_transaction_id")

            redirect("/users/slo_callback?path=#{path}")
          else
            raise OneLogin::RubySaml::ValidationError.new('decidim.spid.slo_request.failure')
          end
        end
      end

      def generate_logout_request(settings)
        logout_request = Decidim::SpidCie::Logoutrequest.new()
        session["saml_transaction_id"] = logout_request.uuid

        if settings.name_identifier_value.nil?
          settings.name_identifier_value = session[:"#{options["name"]}-uid"]
        end

        if settings.sessionindex.nil?
          settings.sessionindex = session[:"#{options["name"]}-index"]
        end

        logout_request.create(settings, RelayState: '/')
      end

      def other_phase_for_spslo
        with_auth_settings do |settings|
          redirect(generate_logout_request(settings))
        end
      end

      def redirect_to(uri)
        pp = CGI.parse(URI.parse(uri).query)
        if pp["Signature"].present?
          r = Rack::Response.new
          if options[:iframe]
            r.write("<script type='text/javascript' charset='utf-8'>top.location.href = '#{uri}';</script>")
          else
            r.write("Redirecting to #{uri}...")
            r.redirect(uri)
          end
        else
          r = Rack::Response.new "
            <html><body onload='javascript:document.forms[0].submit()'>
              <form method='post' action='#{uri.split("?").first}'>
                <input type='hidden' name='SAMLRequest' value='#{Base64.encode64(OneLogin::RubySaml::SamlMessage.new.send(:decode_raw_saml, pp["SAMLRequest"].first))}'>
                <input type='hidden' name='RelayState' value='#{pp["RelayState"].first}'>
                <input type='submit' value='Invia'/>
              </form>
          </body></html>",
                                 200,
                                 { 'Content-Type' => 'text/html' }

        end

        r.finish
      end

    end
  end
end

OmniAuth.config.add_camelization 'saml', 'SAML'
