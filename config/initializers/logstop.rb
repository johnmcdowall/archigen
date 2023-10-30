# frozen_string_literal: true

unless Rails.env.local?
  Logstop.guard(Rails.logger)
end