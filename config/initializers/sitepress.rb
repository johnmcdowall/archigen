Rails.application.config.to_prepare do
  if defined?(Sitepress::SiteController)
    Sitepress::SiteController.class_eval do
      skip_before_action :authenticate, raise: false
    end
  end
end
