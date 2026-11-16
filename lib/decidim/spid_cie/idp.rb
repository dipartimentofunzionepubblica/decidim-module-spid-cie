# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Classe che gestisce lista Idp

require 'rails'
module Decidim
  module SpidCie
    class Idp

      attr_reader :metadata_url

      def self.find_cie(name)
        target = list('cie').with_indifferent_access
        raise 'Idp not found' unless target.key?(name.to_s)
        idp_attributes = target[name.to_s]
        new(**idp_attributes.symbolize_keys)
      end

      def self.find_spid(name)
        target = list('spid').with_indifferent_access
        raise 'Idp not found' unless target.key?(name.to_s)
        idp_attributes = target[name.to_s]
        new(**idp_attributes.symbolize_keys)
      end

      def self.all_spid
        list('spid')
      end

      def self.all_cie
        list('cie')
      end

      def self.import(file_path)
        list = YAML.load_file(file_path)[::Rails.env]
        list.each do |name, params|
          list[name] = params
        end
      end

      def initialize(metadata_url:, validate_cert: , entityName:, logo:)
        @metadata_url = metadata_url
        @validate_cert = validate_cert
      end

      def validate_cert?
        @validate_cert
      end

      def self.list(type)
        idp_path = if File.exist?(Rails.root.join('config', 'idp_list.yml'))
                     Rails.root.join('config', 'idp_list.yml')
                   else
                     Decidim::Spid::Engine.root.join('config', 'idp_list.yml')
                   end
        yaml = YAML.load_file(idp_path)
        yaml.dig(Rails.env.to_s, type.to_s) || yaml.dig("development", type.to_s) || {}
      end

    end

  end
end