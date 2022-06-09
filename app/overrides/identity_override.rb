module Decidim
  class Identity

    def self.log_presenter_class_for(_log)
      Decidim::Spid::AdminLog::IdentityPresenter
    end

  end
end