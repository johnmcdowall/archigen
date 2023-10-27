Rails.application.config.to_prepare do
  require_relative '../../app/content/helpers/page_helper'
  if defined?(Sitepress::SiteController)


    Sitepress::SiteController.class_eval do
      skip_before_action :authenticate, raise: false
    end
  end
end
