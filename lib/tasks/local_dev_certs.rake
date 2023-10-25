# frozen_string_literal: true

namespace :local_dev_certs do
  desc "Generate the local certs required for SSL"
  task :generate do
    sh "mkcert -cert-file .docker/certs/shared.crt -key-file .docker/certs/shared.key *.app.test app.test"
  end
end