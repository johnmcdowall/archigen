empty_directory_with_keep_file "app/frontend/fonts"
empty_directory_with_keep_file "app/frontend/images"

copy_file "app/frontend/stylesheets/index.css"

copy_file "app/frontend/images/example.svg"
copy_file "app/frontend/images/starburst.svg"
copy_file "app/helpers/inline_svg_helper.rb"
copy_file "test/helpers/inline_svg_helper_test.rb"

copy_file "app/frontend/libs/postcss_rename_component.js"
copy_file "app/frontend/libs/import_stimulus_controllers.js"
copy_file "app/frontend/libs/tailwind_multi_theme_plugin.js"

prepend_to_file "app/frontend/entrypoints/application.js", <<~JS
  import "@hotwired/turbo-rails";
JS

prepend_to_file "app/frontend/entrypoints/application.js", <<~JS
  import "~/controllers";
  import { registerControllers } from "../libs/import_stimulus_controllers";
JS

append_to_file "app/frontend/entrypoints/application.js", <<~JS
  let controllers = import.meta.globEager("../../components/**/component.js");
  registerControllers(window.Stimulus, controllers);
JS

copy_file "app/frontend/entrypoints/application.css"

# Remove sprockets
gsub_file "Gemfile", /^gem "sprockets.*\n/, ""
remove_file "config/initializers/assets.rb"
remove_dir "app/assets"
comment_lines "config/environments/development.rb", /^\s*config\.assets\./
comment_lines "config/environments/production.rb", /^\s*config\.assets\./
