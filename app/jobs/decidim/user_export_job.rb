# frozen_string_literal: true

module Decidim
  class UserExportJob < ApplicationJob
    queue_as :default

    def perform(user, participatory_space, name, format)
      collection = participatory_space.users
      serializer = Decidim::Spid::UserSerializer

      export_data = Decidim::Exporters.find_exporter(format).new(collection, serializer).export

      Decidim::ExportMailer.export(user, name, export_data).deliver_now
    end
  end
end
