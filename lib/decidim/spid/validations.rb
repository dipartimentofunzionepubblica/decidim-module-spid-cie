# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# modulo con validazioni SAML

module Decidim
  module Spid
    module Validations

      def validate!
        validations = [
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

        validations.each { |validation| send(validation) }
        @response.errors.empty?
      end

      def append_error(error_msg, soft_override = nil)
        @response.errors << error_msg
        Rails.logger.debug("decidim-module-spid-cie || #{error_msg}")
        
        unless soft_override.nil? ? @response.soft : soft_override
          raise OneLogin::RubySaml::ValidationError.new(error_msg)
        end

        false
      end

      def issue_instant_min
        instant = extract_value('/p:Response/@IssueInstant').to_s
        return true if (instant.present? && Time.parse(instant).iso8601(3).to_time >=
          Time.parse(@sso_params.dig("issue_instant")).iso8601(3).to_time rescue false)

        append_error("IssueInstant deve essere presente e maggiore a quello inviato nella Request")
        false
      end

      def issue_instant_max
        instant = extract_value('/p:Response/@IssueInstant').to_s
        return true if (instant.present? && Time.parse(instant).iso8601(3).to_time <=
          (Time.parse(@sso_params.dig("issue_instant")).iso8601(3).to_time + 3.minutes) rescue false)

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
          Time.parse(@sso_params.dig("issue_instant")).iso8601(3).to_time rescue false)

        append_error("IssueInstant deve essere presente e maggiore a quello inviato nella Request")
        false
      end

      def assertion_issue_instant_max
        instant = extract_value('/p:Response/a:Assertion/@IssueInstant').to_s
        return true if (instant.present? && Time.parse(instant).iso8601(3).to_time <=
          (Time.parse(@sso_params.dig("issue_instant")).iso8601(3).to_time + 3.minutes) rescue false)

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

        if @response.settings.consumer_services.present?
          url = @response.settings.consumer_services[@response.settings.current_consumer_index]['Location']
        else
          url = @response.settings.assertion_consumer_service_url
        end

        return true if !recipient.to_s.blank? && !response_to.nil? && !after.nil? && url == recipient.to_s

        append_error("Assertion SubjectConfirmation deve essere presente e conforme")
        false
      end

      def assertion_conditions_empty
        conditions = extract_value('/p:Response/a:Assertion/a:Conditions').has_elements?
        before = extract_value('/p:Response/a:Assertion/a:Conditions/@NotBefore')
        after = extract_value('/p:Response/a:Assertion/a:Conditions/@NotOnOrAfter')

        return true if conditions && before.present? && after.present?

        append_error("Assertion Conditions devono essere valorizzate")
        false
      end

      def assertion_authncontext
        ref = extract_value('/p:Response/a:Assertion/a:AuthnStatement/a:AuthnContext/a:AuthnContextClassRef').get_text()

        return true if ref.present?

        append_error("Assertion AuthContextClassRef devono essere valorizzate")
        false
      end

      def check_authn_context_class_ref
        ref = extract_value('/p:Response/a:Assertion/a:AuthnStatement/a:AuthnContext/a:AuthnContextClassRef').get_text().to_s
        auth, level = ref[0..-2], ref[-1]

        return true if (ref.present? && level.present? && auth == @authn_context && level.to_i >= @sso_params.dig(key_level) rescue false)

        append_error("Assertion AuthContextClassRef non sufficiente")
        false
      end

      def check_attributes_presence
        return true if @response.attributes.attributes.all? { |k, v| v.present? }

        append_error("AttributeStatement AttributeStatement non specificato")
        false
      end

      def extract_value(value)
        REXML::XPath.first(
          response.document, value,
          { "p" => response.class::PROTOCOL, "a" => response.class::ASSERTION },
          { 'id' => response.document.signed_element_id }
        )
      end

    end
  end
end