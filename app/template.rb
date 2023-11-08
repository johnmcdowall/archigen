copy_file "app/controllers/concerns/basic_auth.rb"
copy_file "app/helpers/layout_helper.rb"

insert_into_file "app/controllers/application_controller.rb", after: /^class ApplicationController.*\n/ do
  <<-RUBY
  include BasicAuth
  RUBY
end

copy_file "app/views/shared/_flash.html.erb"
copy_file "app/views/shared/_nav.html.erb"
copy_file "app/views/shared/_footer.html.erb"

directory "app/components", recurse: true
apply "app/lib/template.rb"

copy_file "app/controllers/dashboard_controller.rb"
copy_file "app/views/dashboard/index.html.erb"

copy_file "app/controllers/waitlist_emails_controller.rb"
directory "app/views/waitlist_emails"

directory "app/views/mailers"

directory "app/controllers/sitepress"

insert_into_file "app/helpers/application_helper.rb", <<-RUBY, after: "module ApplicationHelper"
  def application_name
    Rails.application.class.module_parent_name
  end

  def current_page_title
    (defined?(current_page) && current_page.data["title"]) || title
  end
RUBY

directory "app/models"
directory "app/validators"

insert_into_file "app/controllers/application_controller.rb", <<-RUBY, after: "before_action :authenticate"
  after_action :track_action

  protected

  def track_action
    ahoy.track "Ran action", request.path_parameters
  end
RUBY

directory "app/views/components/app"
directory "app/views/components/ui"
