module Decidim
  module Spid
    module Generators
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path('templates', __dir__)

        desc "Creates a Decidim SPID initializer" #", copy Identity Provider config file and add routes"

        def copy_initializer
          template "decidim-spid.rb", "config/initializers/decidim-spid.rb"
        end

        # def copy_locale
        #   # copy_file "../../../../config/idp_list.yml", "config/idp_list.yml"
        # end
        #
        # def add_spid_routes
        #   # devise_route = "mount Spid::Engine, at: \"/\#\{Spid.mount_point\}\", as: :spid\n".dup
        #   # devise_route << %Q(, class_name: "#{class_name}") if class_name.include?("::")
        #   # devise_route << %Q(, skip: :all) unless options.routes?
        #   # route devise_route
        # end
      end

    end
  end
end