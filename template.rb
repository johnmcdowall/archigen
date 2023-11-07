require 'bundler'
require 'json'
RAILS_REQUIREMENT = '~> 7.0.0'.freeze
NODE_REQUIREMENTS = ['~> 16.14', '>= 18.0.0'].freeze

def apply_template!
  # assert_minimum_rails_version
  assert_minimum_node_version
  assert_valid_options
  assert_postgresql
  add_template_repository_to_source_path

  self.options = options.merge({
                                 css: nil,
                                 skip_asset_pipeline: true,
                                 javascript: 'vite'
                               })

  template 'Gemfile.tt', force: true

  template 'README.md.tt', force: true
  remove_file 'README.rdoc'

  template 'example.env.tt'
  copy_file 'editorconfig', '.editorconfig'
  copy_file 'erb-lint.yml', '.erb-lint.yml'
  copy_file 'overcommit.yml', '.overcommit.yml'
  copy_file 'themes.json'
  template 'node-version.tt', '.node-version', force: true
  template 'ruby-version.tt', '.ruby-version', force: true

  copy_file 'Thorfile'
  copy_file 'Procfile'
  copy_file 'package.json'
  copy_file 'tailwind.config.js'

  apply 'Rakefile.rb'
  apply 'config.ru.rb'
  apply 'bin/template.rb'
  apply 'github/template.rb'
  apply 'devcontainer/template.rb'
  apply 'docker/template.rb'
  apply 'config/template.rb'
  apply 'lib/template.rb'
  apply 'test/template.rb'

  directory 'public'

  empty_directory_with_keep_file 'app/lib'

  git :init unless preexisting_git_repo?
  empty_directory '.git/safe'

  after_bundle do
    append_to_file '.gitignore', <<~IGNORE

      # Ignore application config.
      /.env.development
      /.env.*local

      # Ignore locally-installed gems.
      /vendor/bundle/
    IGNORE

    File.rename('app/javascript', 'app/frontend') if File.exist?('app/javascript')

    copy_file 'postcss.config.js'
    copy_file 'vite.config.ts', force: true
    run_with_clean_bundler_env 'bundle exec vite install'
    run 'yarn add autoprefixer postcss rollup vite-plugin-rails'
    apply 'app/frontend/template.rb'
    rewrite_json('config/vite.json') do |vite_json|
      vite_json['test']['autoBuild'] = false
    end

    apply 'app/template.rb'

    create_database_and_initial_migration
    run_with_clean_bundler_env 'bin/setup'

    binstubs = %w[brakeman bundler bundler-audit erb_lint rubocop sidekiq thor]
    run_with_clean_bundler_env "bundle binstubs #{binstubs.join(' ')} --force"

    remove_file 'Procfile.dev' unless File.exist?('bin/dev')

    copy_file 'rubocop.yml', '.rubocop.yml'
    run_rubocop_autocorrections

    template 'eslintrc.js', '.eslintrc.js'
    template 'prettierrc.js', '.prettierrc.js'
    template 'stylelintrc.js', '.stylelintrc.js'
    add_yarn_lint_and_run_fix
    add_yarn_start_script

    Thor::Base.shell.new.say_status :OK, 'Adding Tailwind and PostCSS configs...'
    add_tailwind_and_postcss
    copy_file 'tailwind.config.js'

    simplify_package_json_deps

    append_to_file '.gitignore', 'node_modules' unless File.read('.gitignore').match?(%(^/?node_modules))

    setup_authentication_zero!

    setup_waitlist_email!
    fixup_mailers!
    fixup_model_ordering!

    run_with_clean_bundler_env 'rails db:migrate'

    setup_phlex!
    setup_madmin!
    setup_sitepress!
    setup_ahoy!
    setup_ahoy_captain!
    setup_blazer!
    setup_anyway_config!

    run_with_clean_bundler_env 'bundle lock --add-platform x86_64-linux'
    run_with_clean_bundler_env 'rake disposable_email:download'

    unless any_local_git_commits?
      git checkout: '-b main'
      git add: '-A .'
      git commit: "-n -m 'Set up project'"
      if git_repo_specified?
        git remote: "add origin #{git_repo_url.shellescape}"
        git push: '-u origin --all'
      end
    end
  end
end

def setup_phlex!
  run_with_clean_bundler_env 'bin/rails generate phlex:install'
  remove_file 'app/views/application_layout.html.erb'
end

def setup_anyway_config!
  run_with_clean_bundler_env 'rails g anyway:install'
  run_with_clean_bundler_env 'yes | rails g anyway:config admin email'

  copy_file 'app/mailers/admin_mailer.rb'
end

def setup_madmin!
  run_with_clean_bundler_env 'rails g madmin:install'
  gsub_file 'config/routes.rb', 'draw :madmin', ''

  insert_into_file 'config/routes.rb', <<-RUBY, after: /with_admin_auth do$/

    draw :madmin
  RUBY
end

def setup_ahoy!
  run_with_clean_bundler_env 'bin/rails g ahoy:install'
  run_with_clean_bundler_env 'bin/rails g db:migrate'

  run_with_clean_bundler_env 'yarn add ahoy.js'
  gsub_file 'config/initializers/ahoy.rb', 'Ahoy.geocode = false', 'Ahoy.geocode = true'
  gsub_file 'config/initializers/ahoy.rb', 'Ahoy.api = false', 'Ahoy.api = true'

  insert_into_file 'config/initializers/ahoy.rb', <<-RUBY
  Ahoy.mask_ips = true
  Ahoy.cookies = :none
  Ahoy.user_method = ->(controller) { Current.user }
  RUBY
end

def setup_ahoy_captain!
  run_with_clean_bundler_env 'bin/rails g ahoy_captain:install'

  gsub_file 'config/routes.rb', "mount AhoyCaptain::Engine => '/ahoy_captain'", ''

  insert_into_file 'config/routes.rb', <<-RUBY, after: /with_admin_auth do$/

    mount AhoyCaptain::Engine => '/ahoy_captain'
  RUBY

  insert_into_file 'app/controllers/application_controller.rb', <<-RUBY, before: /private/
  after_action :track_action

  protected

  def track_action
    ahoy.track "Ran action", request.path_parameters
  end

  RUBY
end

def setup_blazer!
  run_with_clean_bundler_env 'bin/rails g blazer:install'
  run_with_clean_bundler_env 'bin/rails db:migrate'

  insert_into_file 'config/routes.rb', <<-RUBY, after: /with_admin_auth do$/

    mount Blazer::Engine, at: "blazer"
  RUBY
end

def setup_sitepress!
  run_with_clean_bundler_env 'bin/rails g sitepress:install'
  run_with_clean_bundler_env 'bin/rails g markdown_rails:install'
  remove_file 'app/content/pages/index.html.erb'
  copy_file 'config/initializers/sitepress.rb'
  directory 'app/content'

  insert_into_file 'app/controllers/application_controller.rb', <<-RUBY, after: 'class ApplicationController < ActionController::Base'

  layout -> { ApplicationLayout }
  RUBY

  remove_file 'app/views/layouts/application_layout.html.erb'
  remove_file 'app/views/layouts/base_layout.html.erb'
  directory 'app/views/layouts', force: true
end

def setup_authentication_zero!
  run_with_clean_bundler_env 'bin/rails g authentication --lockable --sudoable --trackable --omniauthable --passwordless --initable --masqueradable --tenantable'
  run_with_clean_bundler_env 'bundle install'

  insert_into_file 'app/controllers/home_controller.rb', after: 'class HomeController < ApplicationController' do
    <<-RUBY

  skip_before_action :authenticate
    RUBY
  end

  insert_into_file 'app/controllers/registrations_controller.rb', after: 'skip_before_action :authenticate' do
    <<-RUBY

    before_action :confirm_signup_eligibility, only: [:create]
    RUBY
  end

  insert_into_file 'app/controllers/registrations_controller.rb', after: 'private' do
    <<-RUBY

      def confirm_signup_eligibility
        @waitlist_email = WaitlistEmail.where(email: user_params[:email], approved: true).where.not(confirmed_at: nil).first

        unless @waitlist_email.present?
          redirect_to root_path, notice: "You are not allowed to signup yet." and return
        end
      end
    RUBY
  end

  run_with_clean_bundler_env 'bin/rails g migration add_admin_to_users admin:boolean'
  admin_migration_file = find_migration_by_name('add_admin_to_users')
  gsub_file admin_migration_file, 'add_column :users, :admin, :boolean',
            'add_column :users, :admin, :boolean, default: false'

  gsub_file 'config/routes.rb', 'root "home#index"', ''
end

def setup_waitlist_email!
  run_with_clean_bundler_env 'bin/rails g model WaitlistEmail email:citext:uniq approved:boolean confirmed_at:timestamp'

  insert_into_file 'config/routes.rb', <<-RUBY, before: /^end$/

  scope :waitlist, as: :waitlist_emails do
    post "/join", to: "waitlist_emails#create"
    get "/thanks", to: "waitlist_emails#thanks"
    get ":id/confirm", to: "waitlist_emails#confirm", as: :confirm
  end
  RUBY

  insert_into_file 'app/models/waitlist_email.rb', <<-RUBY, after: /class WaitlistEmail < ApplicationRecord$/

    validates :email,
      presence: { message: "You need to supply an email address to be added to the waitlist." },
      uniqueness: { case_sensitive: false, message: "This email can't be added to the waitlist." },
      disposable_email: true

    normalizes :email, with: -> { _1.strip.downcase }
  RUBY
end

def fixup_mailers!
  insert_into_file 'app/mailers/application_mailer.rb', <<-RUBY, after: /class ApplicationMailer < ActionMailer::Base/

  prepend_view_path "app/views/mailers"
  RUBY

  copy_file 'app/mailers/waitlist_mailer.rb'

  run 'mv app/views/user_mailer app/views/mailers/user_mailer'
  remove_dir 'app/views/user_mailer'
end

def fixup_model_ordering!
  insert_into_file 'app/models/application_record.rb', <<-RUBY, after: /primary_abstract_class/
  # Sort records by date of creation instead of primary key
  self.implicit_order_column = :created_at
  RUBY
end

require 'fileutils'
require 'shellwords'

# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require 'tmpdir'
    source_paths.unshift(tempdir = Dir.mktmpdir('rails-template-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      '--quiet',
      'https://github.com/mattbrictson/rails-template.git',
      tempdir
    ].map(&:shellescape).join(' ')

    if (branch = __FILE__[%r{rails-template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
           "You are using #{rails_version}. Continue anyway?"
  exit 1 if no?(prompt)
end

def assert_minimum_node_version
  requirements = NODE_REQUIREMENTS.map { Gem::Requirement.new(_1) }
  node_version = begin
    `node --version`.chomp
  rescue StandardError
    nil
  end
  if node_version.nil?
    raise Rails::Generators::Error, 'This template requires Node, but Node does not appear to be installed.'
  end

  return if requirements.any? { _1.satisfied_by?(Gem::Version.new(node_version[/[\d.]+/])) }

  prompt = "This template requires Node #{NODE_REQUIREMENTS.join(' or ')}. "\
           "You are using #{node_version}. Continue anyway?"
  exit 1 if no?(prompt)
end

# Bail out if user has passed in contradictory generator options.
def assert_valid_options
  valid_options = {
    skip_gemfile: false,
    skip_bundle: false,
    skip_git: false,
    skip_system_test: false,
    skip_test: false,
    skip_test_unit: false,
    skip_asset_pipeline: true,
    css: nil,
    edge: false
  }

  valid_options.each do |key, expected|
    next unless options.key?(key)

    actual = options[key]
    raise Rails::Generators::Error, "Unsupported option: #{key}=#{actual}" unless actual == expected
  end
end

def assert_postgresql
  return if IO.read('Gemfile') =~ /^\s*gem ['"]pg['"]/

  raise Rails::Generators::Error, 'This template requires PostgreSQL, but the pg gem isn’t present in your Gemfile.'
end

def git_repo_url
  @git_repo_url ||=
    ask_with_default('What is the git remote URL for this project?', :blue, 'skip')
end

def production_hostname
  @production_hostname ||=
    ask_with_default('Production hostname?', :blue, 'example.com')
end

def gemfile_entry(name, version = nil, require: true, force: false)
  @original_gemfile ||= IO.read('Gemfile')
  entry = @original_gemfile[/^\s*gem #{Regexp.quote(name.inspect)}.*$/]
  return if entry.nil? && !force

  require = (entry && entry[/\brequire:\s*(\S+)/, 1]) || require
  version = (entry && entry[/, "([^"]+)"/, 1]) || version
  args = [name.inspect, version&.inspect, ('require: false' if require != true)].compact
  "gem #{args.join(', ')}\n"
end

def ask_with_default(question, color, default)
  return default unless $stdin.tty?

  question = (question.split('?') << " [#{default}]?").join
  answer = ask(question, color)
  answer.to_s.strip.empty? ? default : answer
end

def git_repo_specified?
  git_repo_url != 'skip' && !git_repo_url.strip.empty?
end

def preexisting_git_repo?
  @preexisting_git_repo ||= (File.exist?('.git') || :nope)
  @preexisting_git_repo == true
end

def any_local_git_commits?
  system('git log > /dev/null 2>&1')
end

def run_with_clean_bundler_env(cmd)
  success = if defined?(Bundler)
              if Bundler.respond_to?(:with_original_env)
                Bundler.with_original_env { run(cmd) }
              else
                Bundler.with_clean_env { run(cmd) }
              end
            else
              run(cmd)
            end
  return if success

  puts "Command failed, exiting: #{cmd}"
  exit(1)
end

def run_rubocop_autocorrections
  run_with_clean_bundler_env 'bin/rubocop -A --fail-level A > /dev/null || true'
  run_with_clean_bundler_env 'bin/erblint --lint-all -a > /dev/null || true'
end

def find_migration_by_name(migration_name)
  migrations_dir = File.join('.', 'db', 'migrate')
  migration_file = Dir.entries(migrations_dir).find do |file|
    file =~ /.*_#{migration_name}.rb/
  end

  return unless migration_file

  File.join(migrations_dir, migration_file)
end

def create_database_and_initial_migration
  return if Dir['db/migrate/**/*.rb'].any?

  run_with_clean_bundler_env 'bin/rails db:create'
  run_with_clean_bundler_env 'bin/rails generate migration initial_migration'

  initial_migration_file = find_migration_by_name('initial_migration')
  insert_into_file initial_migration_file, after: /def change/ do
    <<-RUBY

    # All extensions are supported on AWS RDS PG:
    # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts.General.FeatureSupport.Extensions.13x

    # Required for generating UUIDs in the DB
    configure_extension 'pgcrypto'

    # Allows you to see which queries have been running since the last statistics reset, and how they were performing
    configure_extension 'pg_stat_statements'

    # Case insensitive column type
    configure_extension 'citext'

    # Allow creating functions and triggers
    configure_extension 'plpgsql'
    RUBY
  end

  insert_into_file initial_migration_file, before: /def change/ do
    <<-RUBY
      def configure_extension(extension_name)
        enable_extension(extension_name) unless extension_enabled?(extension_name)
      end
    RUBY
  end
end

def add_yarn_start_script
  return add_package_json_script(start: 'bin/dev') if File.exist?('bin/dev')

  procs = ["'bin/rails s -b 0.0.0.0'"]
  procs << "'bin/vite dev'"

  add_package_json_script(start: "stale-dep && concurrently -i -k --kill-others-on-fail -p none #{procs.join(' ')}")
  add_package_json_script(postinstall: 'stale-dep -u')
  run_with_clean_bundler_env 'yarn add concurrently stale-dep'
end

def add_tailwind_and_postcss
  packages = %w[
    postcss-import-ext-glob
    postcss-import
    tailwindcss
    @tailwindcss/forms
    @tailwindcss/typography
    @tailwindcss/aspect-ratio
  ]

  run_with_clean_bundler_env "yarn add #{packages.map(&:shellescape).join(' ')}"
  run_with_clean_bundler_env 'yarn fix'
end

def add_yarn_lint_and_run_fix
  packages = %w[
    eslint
    eslint-config-prettier
    eslint-plugin-prettier
    npm-run-all
    postcss
    prettier
    stale-dep
    stylelint
    stylelint-config-standard
    stylelint-declaration-strict-value
    stylelint-prettier
  ]
  add_package_json_script("fix": 'npm-run-all fix:**')
  add_package_json_script("fix:js": 'npm run -- lint:js --fix')
  add_package_json_script("fix:css": 'npm run -- lint:css --fix')
  add_package_json_script("lint": 'npm-run-all lint:**')
  add_package_json_script("lint:js": "stale-dep && eslint 'app/{components,frontend,javascript}/**/*.{js,jsx}'")
  add_package_json_script("lint:css": "stale-dep && stylelint 'app/{components,frontend,assets/stylesheets}/**/*.css'")
  add_package_json_script("postinstall": 'stale-dep -u')
  run_with_clean_bundler_env "yarn add #{packages.map(&:shellescape).join(' ')}"
  run_with_clean_bundler_env 'yarn fix'
end

def add_package_json_script(scripts)
  scripts.each do |name, script|
    run ['npm', 'pkg', 'set', "scripts.#{name.to_s.shellescape}=#{script.shellescape}"].join(' ')
  end
end

def simplify_package_json_deps
  rewrite_json('package.json') do |package_json|
    package_json['dependencies'] = package_json['dependencies']
                                   .merge(package_json.delete('devDependencies') || {})
                                   .sort_by { |key, _| key }
                                   .to_h
  end
  run_with_clean_bundler_env 'yarn install'
end

def rewrite_json(file)
  json = JSON.parse(File.read(file))
  yield(json)
  File.write(file, JSON.pretty_generate(json) + "\n")
end

apply_template!
