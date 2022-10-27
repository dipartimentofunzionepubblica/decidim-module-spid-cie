# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

require 'omniauth'
require 'ruby-saml'
require 'decidim/spid/utils'
require 'decidim/spid/models'

# Strategia SPID SAML personalizzata secondo le configurazioni nell'initializer

module OmniAuth
  module Strategies
    class SpidSaml
      include OmniAuth::Strategy

      def self.inherited(subclass)
        OmniAuth::Strategy.included(subclass)
      end

      include Decidim::Spid::Utils
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
        @options = OmniAuth::Strategy::Options.new(options.merge(tenant ? tenant.config: {}))
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
      option :attribute_service_name, I18n.t('decidim_spid.required_attributes')
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
        redirect sso_saml(sso_params, options)
      end

      def sso_params
        sso_params = {}
        sso_params[:sso] = { idp: request.params.dig("sso", "idp") }
        sso_params[:spid_level] = options.spid_level
        sso_params[:host] = options.sp_entity_id
        sso_params[:relay_state] = Base64.strict_encode64(request.params.dig("sso", "origin").presence || options.relay_state || options.sp_entity_id )
        sso_params
      end

      def callback_phase
        raise OneLogin::RubySaml::ValidationError.new("SAML response missing") unless request.params["SAMLResponse"]

        with_settings do |settings|
          handle_response(request.params["SAMLResponse"], options_for_response_object, settings) do
            super
          end
        end
      rescue OneLogin::RubySaml::ValidationError
        fail!(:invalid_ticket, $!)
      end

      def response_fingerprint
        response = request.params["SAMLResponse"]
        response = (response =~ /^</) ? response : Base64.decode64(response)
        document = XMLSecurity::SignedDocument::new(response)
        cert_element = REXML::XPath.first(document, "//ds:X509Certificate", { "ds"=> 'http://www.w3.org/2000/09/xmldsig#' })
        base64_cert = cert_element.text
        cert_text = Base64.decode64(base64_cert)
        cert = OpenSSL::X509::Certificate.new(cert_text)
        Digest::SHA1.hexdigest(cert.to_der).upcase.scan(/../).join(':')
      end

      def other_phase
        if request_path_pattern.match(current_path) || custom_path_pattern_matches?(current_path)
          @env['omniauth.strategy'] ||= self
          setup_phase

          if on_subpath?(:metadata) || on_custom_metadata
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
          false
        end
      end

      def on_custom_slo?(subpath)
        logout_path == current_path || (response_path == current_path && request.params["SAMLResponse"].present?)
      end

      def on_custom_metadata
        metadata_path == current_path
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
      extra { { :raw_info => @attributes.attributes } }

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
          # response.attributes["fingerprint"] = settings.idp_cert_fingerprint
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
        valid, msg, r = sso_request(raw_response, options)
        if valid
          @name_id = r.name_id.try(:strip)
          @response_object = r
          r.attributes["fingerprint"] = r.settings.idp_cert_fingerprint if r.settings.idp_cert_fingerprint
          @attributes =  r.attributes
          yield if block_given?
        else
          raise OneLogin::RubySaml::ValidationError.new(msg)
        end

      end

      def slo_relay_state
        if request.params.has_key?("RelayState") && request.params["RelayState"] != ""
          request.params["RelayState"]
        else
          slo_default_relay_state = options.slo_default_relay_state
          if slo_default_relay_state.respond_to?(:call)
            if slo_default_relay_state.arity == 1
              slo_default_relay_state.call(request)
            else
              slo_default_relay_state.call
            end
          else
            slo_default_relay_state
          end
        end
      end

      def with_settings
        options[:consumer_services] = options[:consumer_services].present? ? options[:consumer_services] : callback_url
        options[:logout_services] = options[:logout_services].present? ? options[:logout_services] : logout_url
        yield OneLogin::RubySaml::Settings.new(options)
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
                          # path ||= custom_path(:metadata_path)
                          path ||= "#{script_name}#{path_prefix}/#{name}/metadata"
                          path
                        end
      end

      def options_for_response_object
        opts = options.select {|k,_| RUBYSAML_RESPONSE_OPTIONS.include?(k.to_sym)}

        opts.inject({}) do |new_hash, (key, value)|
          new_hash[key.to_sym] = value
          new_hash
        end
      end

      def other_phase_for_metadata
        metadata = Decidim::Spid::Metadata.new
        xml = metadata.to_xml(Decidim::Spid::Settings::Metadata.new(options))
        Rack::Response.new(xml, 200, { "Content-Type" => "application/xml" }).finish
      end

      def other_phase_for_slo
        path = Base64.strict_decode64(session[:"#{session_prefix}sso_params"]["relay_state"]) rescue options["relay_state"]
        valid, msg = slo_request(request.params["SAMLResponse"], options)

        if valid
          redirect("/users/slo_callback?success=#{valid}&path=#{path}")
        else
          raise OneLogin::RubySaml::ValidationError.new(msg)
        end
      end

      def other_phase_for_spslo
        redirect slo_saml(slo_params, options)
      end

      def add_request_attributes_to(settings)
        settings.attribute_consuming_service.service_name options.attribute_service_name
        settings.sp_entity_id = options.sp_entity_id

        options.request_attributes.each do |attribute|
          settings.attribute_consuming_service.add_attribute attribute
        end
      end

      def additional_params_for_authn_request
        {}.tap do |additional_params|
          runtime_request_parameters = options.delete(:idp_sso_service_url_runtime_params)

          if runtime_request_parameters
            runtime_request_parameters.each_pair do |request_param_key, mapped_param_key|
              additional_params[mapped_param_key] = request.params[request_param_key.to_s] if request.params.has_key?(request_param_key.to_s)
            end
          end
        end
      end

    end
  end
end

OmniAuth.config.add_camelization 'saml', 'SAML'
