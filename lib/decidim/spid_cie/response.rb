require "onelogin/ruby-saml/response"

module Decidim
  module SpidCie
    #
    class Response < ::OneLogin::RubySaml::Response

      def initialize(response, options = {}, params)
        @params = params
        super(response, options)
      end

      def validate(collect_errors = false)
        reset_errors!
        return false unless validate_response_state

        validations = [
          :validate_version,
          :validate_id,
          :validate_success_status,
          :validate_num_assertion,
          :validate_signed_elements,
          :validate_structure,
          :validate_no_duplicated_attributes,
          :validate_in_response_to,
          :validate_one_conditions,
          :validate_conditions,
          :validate_one_authnstatement,
          :validate_audience,
          :validate_destination,
          :validate_issuer,
          :validate_session_expiration,
          :validate_subject_confirmation,
          :validate_name_id,
          :validate_signature,

          # CUSTOM
          :issue_instant_min,
          :issue_instant_max,
          :destination_presence,
          :format_issuers,
          :assertion_version,
          :assertion_issue_instant_min,
          :assertion_issue_instant_max,
          :assertion_name_id,
          :assertion_subject_confirmation,
          :assertion_conditions_empty,
          :assertion_authncontext,
          :check_authn_context_class_ref,
          :check_attributes_presence
        ]

        if collect_errors
          validations.each { |validation| send(validation) }
          @errors.empty?
        else
          validations.all? { |validation| send(validation) }
        end
      end

      def validate_destination
        return true if destination.nil?
        return true if options[:skip_destination]

        if destination.empty?
          error_msg = "The response has an empty Destination value"
          return append_error(error_msg)
        end

        if settings.consumer_services.present?
          url = settings.consumer_services[settings.current_consumer_index]['Location'] rescue ''
          unless ::OneLogin::RubySaml::Utils.uri_match?(destination, url)
            error_msg = "The response was received at #{destination} instead of #{url}"
            return append_error(error_msg)
          else
            return true
          end
        else
          return true if settings.assertion_consumer_service_url.nil? || settings.assertion_consumer_service_url.empty?
        end

        unless ::OneLogin::RubySaml::Utils.uri_match?(destination, settings.assertion_consumer_service_url)
          error_msg = "The response was received at #{destination} instead of #{settings.assertion_consumer_service_url}"
          return append_error(error_msg)
        end

        true
      end

      def issue_instant_min
        instant = extract_value('/p:Response/@IssueInstant').to_s
        return true if (instant.present? && Time.parse(instant).iso8601(3).to_time >=
          Time.parse(@params.dig("issue_instant")).iso8601(3).to_time rescue false)

        append_error("IssueInstant deve essere presente e maggiore a quello inviato nella Request")
        false
      end

      def issue_instant_max
        instant = extract_value('/p:Response/@IssueInstant').to_s
        return true if (instant.present? && Time.parse(instant).iso8601(3).to_time <=
          (Time.parse(@params.dig("issue_instant")).iso8601(3).to_time + 3.minutes) rescue false)

        append_error("IssueInstant deve essere presente e maggiore a quello inviato nella Request")
        false
      end

      def destination_presence
        dest = extract_value('/p:Response/@Destination').to_s
        return true if dest.present? # Il resto è validato da ruby-saml

        append_error("Destination deve essere presente")
        false
      end

      def format_issuers
        format1 = extract_value('/p:Response/a:Issuer/@Format')
        format2 = extract_value('/p:Response/a:Assertion/a:Issuer/@Format')
        return true if (format1.nil? || format1.present? && format1.to_s == "urn:oasis:names:tc:SAML:2.0:nameid-format:entity") &&
          format2.present? && format2.to_s == "urn:oasis:names:tc:SAML:2.0:nameid-format:entity"

        append_error("Issuer Format non conforme")
        false
      end

      def assertion_version
        version = extract_value('/p:Response/a:Assertion/@Version').to_s
        return true if version.present? && version == "2.0"

        append_error("Assertion Versione non supportato")
        false
      end

      def assertion_issue_instant_min
        instant = extract_value('/p:Response/a:Assertion/@IssueInstant').to_s
        return true if (instant.present? && Time.parse(instant).iso8601(3).to_time >=
          Time.parse(@params.dig("issue_instant")).iso8601(3).to_time rescue false)

        append_error("IssueInstant deve essere presente e maggiore a quello inviato nella Request")
        false
      end

      def assertion_issue_instant_max
        instant = extract_value('/p:Response/a:Assertion/@IssueInstant').to_s
        return true if (instant.present? && Time.parse(instant).iso8601(3).to_time <=
          (Time.parse(@params.dig("issue_instant")).iso8601(3).to_time + 3.minutes) rescue false)

        append_error("IssueInstant deve essere presente e maggiore a quello inviato nella Request")
        false
      end

      def assertion_name_id
        name_id = extract_value('/p:Response/a:Assertion//a:NameID/text()').to_s.try(:strip)
        format_id = extract_value('/p:Response/a:Assertion//a:NameID/@Format').to_s
        name_qualifier = extract_value('/p:Response/a:Assertion//a:NameID/@NameQualifier').to_s

        return true if name_id.present? && format_id.present? && name_qualifier.present? &&
          format_id == "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"

        append_error("Assertion NameID deve essere presente e conforme")
        false
      end

      def assertion_subject_confirmation
        recipient = extract_value('/p:Response/a:Assertion//a:SubjectConfirmation/a:SubjectConfirmationData/@Recipient')
        response_to = extract_value('/p:Response/a:Assertion//a:SubjectConfirmation/a:SubjectConfirmationData/@InResponseTo')
        after = extract_value('/p:Response/a:Assertion//a:SubjectConfirmation/a:SubjectConfirmationData/@NotOnOrAfter')

        if settings.consumer_services.present?
          url = settings.consumer_services[settings.current_consumer_index]['Location']
        else
          url = settings.assertion_consumer_service_url
        end

        return true if !recipient.to_s.blank? && !response_to.nil? && !after.nil? && url == recipient.to_s && response_to.to_s == @params.dig("uuid")

        append_error("Assertion SubjectConfirmation deve essere presente e conforme")
        false
      end

      def assertion_conditions_empty
        conditions = extract_value('/p:Response/a:Assertion/a:Conditions').has_elements? rescue nil
        before = extract_value('/p:Response/a:Assertion/a:Conditions/@NotBefore')
        after = extract_value('/p:Response/a:Assertion/a:Conditions/@NotOnOrAfter')

        return true if conditions && before.present? && after.present?

        append_error("Assertion Conditions devono essere valorizzate")
        false
      end

      def assertion_authncontext
        ref = extract_value('/p:Response/a:Assertion/a:AuthnStatement/a:AuthnContext/a:AuthnContextClassRef').get_text() rescue nil

        return true if ref.present?

        append_error("Assertion AuthContextClassRef devono essere valorizzate")
        false
      end

      def check_authn_context_class_ref
        ref = extract_value('/p:Response/a:Assertion/a:AuthnStatement/a:AuthnContext/a:AuthnContextClassRef').get_text().to_s rescue nil
        auth, level = ref[0..-2], ref[-1] if ref

        return true if (ref.present? && level.present? && settings.authn_context && settings.authn_context.match(auth) && level.to_i >= settings.try(:spid_level) || settings.try(:cie_level) rescue false)

        append_error("Assertion AuthContextClassRef non sufficiente")
        false
      end

      def check_attributes_presence
        return true if attributes.attributes.all? { |k, v| v.present? }

        append_error("AttributeStatement AttributeStatement non specificato")
        false
      end

      def extract_value(value)
        REXML::XPath.first(
          document, value,
          { "p" => self.class::PROTOCOL, "a" => self.class::ASSERTION },
          { 'id' => document.signed_element_id }
        )
      end

    end
  end
end