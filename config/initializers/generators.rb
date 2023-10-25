Rails.application.config.generators do |g|
  # Disable generators we don't need.
  g.javascripts false
  g.stylesheets false

  # We want UUIDs for our primary keys
  g.orm :active_record, primary_key_type: :uuid
end
