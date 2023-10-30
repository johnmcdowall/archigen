return unless defined?(Sidekiq)

# Disable SSL certificate verification if using Heroku Redis
# redis_opts = {
#   ssl_params: {
#     verify_mode: OpenSSL::SSL::VERIFY_NONE
#   }
# }
# Sidekiq.configure_server do |config|
#   config.redis = redis_opts
# end
# Sidekiq.configure_client do |config|
#   config.redis = redis_opts
# end

# Enable Rails CurrentAttributes to flow transparently through to Sidekiq jobs
# require "sidekiq/middleware/current_attributes"
# Sidekiq::CurrentAttributes.persist(Myapp::Current)

require "sidekiq/web"

Sidekiq::Web.app_url = "/"
