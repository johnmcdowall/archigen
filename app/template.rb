copy_file "app/controllers/concerns/basic_auth.rb"
copy_file "app/helpers/layout_helper.rb"

insert_into_file "app/controllers/application_controller.rb", after: /^class ApplicationController.*\n/ do
  <<-RUBY
  include BasicAuth
  RUBY
end

File.rename "app/views/layouts/application.html.erb", "app/views/layouts/base.html.erb"

prepend_to_file "app/views/layouts/base.html.erb", <<~ERB
<%# The "base" layout contains boilerplate common to *all* views. %>
ERB

gsub_file "app/views/layouts/base.html.erb", "<html>", %(<html lang="en" class="antialiased scroll-smooth text-base" data-theme="light">)

insert_into_file "app/views/layouts/base.html.erb", <<-ERB, after: "<head>"

    <!-- #{app_const_base.titleize} <%= Rails.application.config.version %> (<%= l(Rails.application.config.version_time) %>) -->
ERB

gsub_file "app/views/layouts/base.html.erb", %r{^\s*<title>.*</title>}, <<-ERB
    <%= metamagic(
      site: "#{app_const_base.titleize}", title: [:title, :site], separator: " – ",
      description: "#{app_const_base.titleize} description.",
      keywords: "#{app_const_base.titleize} Keywords",
      og: {
        site_name: "Site name",
        title: "Site title",
        description: "Site description",
        # image: image_url('open-graph.jpg')
      })
    %>
    <%# Specifies the default name of home screen bookmark in iOS %>
    <meta name="apple-mobile-web-app-title" content="#{app_const_base.titleize}">
ERB

insert_into_file "app/views/layouts/base.html.erb", <<-ERB.rstrip, before: %r{^\s*</head>}
    <%= yield(:head) %>
ERB

gsub_file "app/views/layouts/base.html.erb", /^.*<%= stylesheet_link_tag.*$/, ""
gsub_file "app/views/layouts/base.html.erb",
          /vite_javascript_tag 'application' %>/, \
          'vite_javascript_tag "application", "data-turbo-track": "reload" %>'

insert_into_file "app/views/layouts/base.html.erb", <<-ERB, after: '<%= vite_javascript_tag "application", "data-turbo-track": "reload" %>'
    <%= vite_stylesheet_tag "application", "data-turbo-track": "reload" %>
ERB

copy_file "app/views/layouts/application.html.erb"
copy_file "app/views/layouts/page.html.erb"
copy_file "app/views/shared/_flash.html.erb"
copy_file "app/views/shared/_nav.html.erb"
copy_file "app/views/shared/_footer.html.erb"

directory "app/components", recurse: true
apply "app/lib/template.rb"

copy_file "app/controllers/dashboard_controller.rb"
copy_file "app/views/dashboard/index.html.erb"

copy_file "app/controllers/waitlist_emails_controller.rb"
directory "app/views/waitlist_emails"

insert_into_file "app/helpers/application_helper.rb", <<-RUBY, after: 'module ApplicationHelper'
  def application_name
    Rails.application.class.module_parent_name
  end
RUBY

directory "app/models"
directory "app/validators"