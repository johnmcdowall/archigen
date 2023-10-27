apply "config/application.rb"
template "config/database.yml", force: true
remove_file "config/secrets.yml"
copy_file "config/sidekiq.yml"

gsub_file "config/routes.rb", /  # root 'welcome#index'/, ''

copy_file "config/initializers/generators.rb"
copy_file "config/initializers/rotate_log.rb"
copy_file "config/initializers/version.rb"
copy_file "config/initializers/sidekiq.rb"


gsub_file "config/initializers/filter_parameter_logging.rb", /\[:password\]/ do
  "%w[password secret session cookie csrf]"
end

apply "config/environments/development.rb"
apply "config/environments/production.rb"
apply "config/environments/test.rb"

route %Q(mount Sidekiq::Web => "/sidekiq" if defined?(Sidekiq) # monitoring console\n)

insert_into_file "config/initializers/inflections.rb", <<~RUBY
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "HTML"
  inflect.acronym "UI"
end
RUBY

remove_file "config/locales/en.yml"
directory "config/locales"