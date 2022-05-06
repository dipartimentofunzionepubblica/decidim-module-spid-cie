module XMLSecurity

  class Document

    def sign_document(private_key, certificate, signature_method = RSA_SHA1, digest_method = SHA1)
      noko = Nokogiri::XML(self.to_s) do |config|
        config.options = XMLSecurity::BaseDocument::NOKOGIRI_OPTIONS
      end

      signature_element = REXML::Element.new("ds:Signature").add_namespace('ds', DSIG)
      signed_info_element = signature_element.add_element("ds:SignedInfo")
      signed_info_element.add_element("ds:CanonicalizationMethod", {"Algorithm" => C14N})
      signed_info_element.add_element("ds:SignatureMethod", {"Algorithm"=>signature_method})

      # Add Reference
      reference_element = signed_info_element.add_element("ds:Reference", {"URI" => "##{uuid}"})

      # Add Transforms
      transforms_element = reference_element.add_element("ds:Transforms")
      transforms_element.add_element("ds:Transform", {"Algorithm" => ENVELOPED_SIG})
      c14element = transforms_element.add_element("ds:Transform", {"Algorithm" => C14N})
      c14element.add_element("ec:InclusiveNamespaces", {"xmlns:ec" => C14N, "PrefixList" => INC_PREFIX_LIST})

      digest_method_element = reference_element.add_element("ds:DigestMethod", {"Algorithm" => digest_method})
      inclusive_namespaces = INC_PREFIX_LIST.split(" ")
      canon_doc = noko.canonicalize(canon_algorithm(C14N), inclusive_namespaces)
      reference_element.add_element("ds:DigestValue").text = compute_digest(canon_doc, algorithm(digest_method_element))

      # add SignatureValue
      noko_sig_element = Nokogiri::XML(signature_element.to_s) do |config|
        config.options = XMLSecurity::BaseDocument::NOKOGIRI_OPTIONS
      end

      noko_signed_info_element = noko_sig_element.at_xpath('//ds:Signature/ds:SignedInfo', 'ds' => DSIG)
      canon_string = noko_signed_info_element.canonicalize(canon_algorithm(C14N))

      signature = compute_signature(private_key, algorithm(signature_method).new, canon_string)
      signature_element.add_element("ds:SignatureValue").text = signature

      # add KeyInfo
      key_info_element       = signature_element.add_element("ds:KeyInfo")
      ##### Patch SPID
      if private_key.is_a?(OpenSSL::PKey::RSA)
        key_value = key_info_element.add_element("ds:KeyValue")
        rsa_key_value = key_value.add_element("ds:RSAKeyValue")
        rsa_key_value.add_element("ds:Modulus").text = Base64.encode64(private_key.n.to_s(2))
        rsa_key_value.add_element("ds:Exponent").text = Base64.encode64(private_key.e.to_s(2))
        key_info_element.add_element(key_value)
      end
      ##### Patch SPID
      x509_element           = key_info_element.add_element("ds:X509Data")
      x509_cert_element      = x509_element.add_element("ds:X509Certificate")
      if certificate.is_a?(String)
        certificate = OpenSSL::X509::Certificate.new(certificate)
      end
      x509_cert_element.text = Base64.encode64(certificate.to_der).gsub(/\n/, "")

      # add the signature
      issuer_element = elements["//saml:Issuer"]
      if issuer_element
        root.insert_after(issuer_element, signature_element)
      elsif first_child = root.children[0]
        root.insert_before(first_child, signature_element)
      else
        root.add_element(signature_element)
      end
    end

  end

end
