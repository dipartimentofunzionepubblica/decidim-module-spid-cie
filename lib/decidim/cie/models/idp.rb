require 'rails'
module Decidim
  module Cie
    class Idp

      attr_reader :metadata_url

      def self.find(name)
        raise 'Idp not found' unless list.key?(name)
        idp_attributes = list[name]
        new(idp_attributes.symbolize_keys)
      end

      def self.all
        list
      end

      def self.import(file_path)
        list = YAML.load_file(file_path)[::Rails.env]
        list.each do |name, params|
          list[name] = params
        end
      end

      def initialize(metadata_url:, validate_cert: true, protocols: nil, entityName: nil, logo: nil)
        @metadata_url = metadata_url
        @validate_cert = validate_cert
      end

      def validate_cert?
        @validate_cert
      end

      def self.list
        list = YAML.load_file(Rails.root.join('config', 'idp_list.yml')).dig("#{Rails.env}").dig("cie")
      end

    end

  end
end