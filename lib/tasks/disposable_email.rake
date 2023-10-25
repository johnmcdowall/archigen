# frozen_string_literal: true

namespace :disposable_email do
  desc "Downloads the list of disposable email domains"
  task download: :environment do
    url = "https://disposable.github.io/disposable-email-domains/domains.txt"
    path = "db/disposable_email_domains.txt"

    File.open(path, "w") do |f|
      f.write(HTTP.get(url).to_s)
    end
  end
end