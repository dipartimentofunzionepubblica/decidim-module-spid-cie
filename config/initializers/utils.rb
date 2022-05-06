module OneLogin
  module RubySaml

    # SAML2 Auxiliary class
    #
    class Utils

      # Given two strings, attempt to match them as URIs using Rails' parse method.  If they can be parsed,
      # then the fully-qualified domain name and the host should performa a case-insensitive match, per the
      # RFC for URIs.  If Rails can not parse the string in to URL pieces, return a boolean match of the
      # two strings.  This maintains the previous functionality.
      # @return [Boolean]
      def self.uri_match?(destination_url, settings_url)
        dest_uri = URI.parse(destination_url.try(:strip))
        acs_uri = URI.parse(settings_url.try(:strip))

        if dest_uri.scheme.nil? || acs_uri.scheme.nil? || dest_uri.host.nil? || acs_uri.host.nil?
          raise URI::InvalidURIError
        else
          dest_uri.scheme.downcase == acs_uri.scheme.downcase &&
            dest_uri.host.downcase == acs_uri.host.downcase &&
            dest_uri.path == acs_uri.path &&
            dest_uri.query == acs_uri.query
        end
      rescue URI::InvalidURIError
        original_uri_match?(destination_url, settings_url)
      end

    end
  end
end
