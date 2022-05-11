require 'omniauth'
require 'ruby-saml'
require 'decidim/cie/utils'
require 'decidim/cie/models'

module OmniAuth
  module Strategies
    class CieSaml
      include OmniAuth::Strategy

      def self.inherited(subclass)
        OmniAuth::Strategy.included(subclass)
      end

      include Decidim::Cie::Utils
      def initialize(app, *args, &block)
        super
        Decidim::Cie::Utils.current_name = options[:name]
        options[:sp_name_qualifier] = options[:sp_entity_id] if options[:sp_name_qualifier].nil?
        options[:issuer] = options[:sp_entity_id]

        [
          :idp_name_qualifier,
          :name_identifier_format,
          :security
        ].each do |key|
          options.delete(key) if options[key].nil?
        end

        tenant = Decidim::Cie.find_tenant(options[:name])
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
      option :attribute_service_name, I18n.t('decidim_cie.required_attributes')
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
        sso_params[:cie_level] = options.cie_level
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

      # Obtain an idp certificate fingerprint from the response.
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
        if request_path_pattern.match(current_path)
          @env['omniauth.strategy'] ||= self
          setup_phase

          if on_subpath?(:metadata)
            other_phase_for_metadata
          elsif on_subpath?(:slo)
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

      extra { { :raw_info => @attributes, :session_index => @session_index, :response_object =>  @response_object } }

      def find_attribute_by(keys)
        keys.each do |key|
          return @attributes[key] if @attributes && @attributes[key]
        end

        nil
      end

      # This method can be used externally to fetch information about the
      # response, e.g. in case of failures.
      def response_object
        return nil unless request.params["SAMLResponse"]

        with_settings do |settings|
          response = OneLogin::RubySaml::Response.new(
            request.params["SAMLResponse"],
            options_for_response_object.merge(settings: settings)
          )
          response.attributes["fingerprint"] = settings.idp_cert_fingerprint
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

      #todo: ridefinire
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
        options[:assertion_consumer_service_url] ||= callback_url
        yield OneLogin::RubySaml::Settings.new(options)
      end

      def options_for_response_object
        # filter options to select only extra parameters
        opts = options.select {|k,_| RUBYSAML_RESPONSE_OPTIONS.include?(k.to_sym)}

        # symbolize keys without activeSupport/symbolize_keys (ruby-saml use symbols)
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
        path = Base64.strict_decode64(session[:"#{session_prefix}sso_params"]["relay_state"])
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
