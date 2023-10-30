# frozen_string_literal: true

namespace :geocoder do
  desc "Download the Maxmind geoip database"
  task download_db: :environment do
    url = ENV["MAXMIND_URL"]
    raise ArgumentError, "Need to supply the MAXMIND_URL env var." unless url.present?

    path = File.join(Rails.root, "db" "GeoLite2-City.mmdb")

    require "net/http"
    require "uri"
    require "progressbar"

    response = HTTP.get(url)
    while response.status.redirect?
      url = URI(response['location'])
      response = HTTP.get(url)
    end

    uri = URI(url)

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new uri

      http.request request do |response|
        if response.code == '200'
          output_file = File.new('downloaded_file.zip', 'wb')
          total_size = response['Content-Length'].to_i
          pbar = ProgressBar.create(total: total_size, format: '%a %E |%b>>%i| %p%% %t')

          response.read_body do |chunk|
            output_file.write(chunk)
            pbar.progress += chunk.size
          end

          pbar.finish
          output_file.close
        else
          puts "Failed to download the file. HTTP Status Code: #{response.code}"
        end
      end
    end
  end
end
