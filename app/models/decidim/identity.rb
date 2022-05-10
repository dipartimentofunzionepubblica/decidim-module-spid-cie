require_dependency Decidim::Core::Engine.root.join('app', 'models', 'decidim', 'identity').to_s

module Decidim
  class Identity


    def self.log_presenter_class_for(_log)
      Decidim::Spid::AdminLog::IdentityPresenter
    end


  end
end