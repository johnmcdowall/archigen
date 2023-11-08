apply "config/application.rb"
template "config/database.yml", force: true
remove_file "config/secrets.yml"
copy_file "config/sidekiq.yml"

directory "config/initializers"

gsub_file "config/initializers/filter_parameter_logging.rb", /\[:password\]/ do
  "%w[password secret session cookie csrf]"
end

apply "config/environments/development.rb"
apply "config/environments/production.rb"
apply "config/environments/test.rb"

insert_into_file "config/initializers/inflections.rb", <<~RUBY
  ActiveSupport::Inflector.inflections(:en) do |inflect|
    inflect.acronym "HTML"
    inflect.acronym "UI"
  end
RUBY

remove_file "config/locales/en.yml"
directory "config/locales"

insert_into_file "config/routes.rb", <<-RUBY, before: /^end$/
  with_admin_auth do
    mount Sidekiq::Web => "/sidekiq" if defined?(Sidekiq) # monitoring console
  end
RUBY

gsub_file "config/routes.rb", /  # root 'welcome#index'/, ""
