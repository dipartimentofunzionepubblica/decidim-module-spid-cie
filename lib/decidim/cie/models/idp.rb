# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

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