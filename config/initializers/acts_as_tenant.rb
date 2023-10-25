# frozen_string_literal: true
require "acts_as_tenant/sidekiq" if defined? Sidekiq

ActsAsTenant.configure do |config|
  config.require_tenant = true
end
