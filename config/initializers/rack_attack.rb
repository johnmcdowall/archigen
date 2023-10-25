require "json"

rate_limit_html = File.read(Rails.root.join("public", "429.html"))

class Rack::Attack
  class Request < ::Rack::Request
    def ip
      remote_ip
    end

    def remote_ip
      # Cloudflare stores remote IP in CF_CONNECTING_IP header
      @remote_ip ||= (env['HTTP_CF_CONNECTING_IP'] ||
                      env['action_dispatch.remote_ip']).to_s
    end
  end
end

Rack::Attack.safelist("allow Testing mode") { |_req| Rails.env.test? }
# Rack::Attack.safelist("allow development") { |req| Rails.env.development? }
Rack::Attack.safelist_ip("192.168.0.0/24")

# Limit data modification requests
Rack::Attack.throttle("unsafe/req/ip", limit: 30, period: 60.seconds) do |req|
  req.remote_ip unless req.get?
end

Rack::Attack.track("admin") do |req|
  req.path.start_with?("/admin")
end

Rack::Attack.throttle("authentication/ip", limit: 30, period: 1.hour) do |req|
  if req.post? &&
       %w[/users/sign_in /users/sign_up /users/password].include?(
         req.path
       )
    req.remote_ip
  end
end

# Block suspicious requests for '/etc/password' or wordpress specific paths.
# After 3 blocked requests in 10 minutes, block all requests from that IP for 5 minutes.
Rack::Attack.blocklist('fail2ban pentesters') do |req|
  # `filter` returns truthy value if request fails, or if it's from a previously banned IP
  # so the request is blocked
  Rack::Attack::Fail2Ban.filter("pentesters-#{req.remote_ip}", maxretry: 3, findtime: 30.minutes, bantime: 60.minutes) do
    # The count for the IP is incremented if the return value is truthy
    CGI.unescape(req.query_string) =~ %r{/etc/passwd} ||
    req.path.include?('/etc/passwd') ||
    req.path.include?('wp-admin') ||
    req.path.include?('wp-login') ||
    req.path.include?('wp-includes') ||
    req.path.include?('xmlrpc') ||
    req.path.include?('php') ||
    req.path.include?('.git') ||
    req.path.include?('.env')
  end

  # Rack::Attack::Fail2Ban.filter("pentesters-lbdirect-#{req.remote_ip}", maxretry: 1, findtime: 30.minutes, bantime: 60.minutes) do
  #   req.host.to_s == "146.190.0.98"
  # end
end

Rack::Attack.blocklisted_responder = lambda do |request|
  # Using 503 because it may make attacker think that they have successfully
  # DOSed the site. Rack::Attack returns 403 for blocklists by default
  [ 503, {}, ["Server Error"]]
end

Rack::Attack.throttled_responder = lambda do |request|
  # NB: you have access to the name and other data about the matched throttle
  #  request.env['rack.attack.matched'],
  #  request.env['rack.attack.match_type'],
  #  request.env['rack.attack.match_data'],
  #  request.env['rack.attack.match_discriminator']
  [ 503, {}, ["Server Error\n"]]
end

ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _request_id, payload|
  req = payload[:request]
  rack_attack_throttle_data = req.env['rack.attack.throttle_data']
  Rails.logger.info "[RACK ATTACK] #{req.env['rack.attack.match_type']} #{req.remote_ip} on #{req.request_method} #{req.fullpath} #{req.env["rack.attack.match_discriminator"]} reason: #{req.env["rack.attack.matched"]}"
  Rails.logger.info rack_attack_throttle_data&.stringify_keys.inspect
end

ActiveSupport::Notifications.subscribe('blocklist.rack_attack') do |_name, _start, _finish, _request_id, payload|
  req = payload[:request]
  Rails.logger.info "[RACK ATTACK] #{req.env['rack.attack.match_type']} #{req.remote_ip} on #{req.request_method} #{req.fullpath} #{req.env["rack.attack.match_discriminator"]} reason: #{req.env["rack.attack.matched"]}"
end

ActiveSupport::Notifications.subscribe("track.rack_attack") do |name, start, finish, request_id, payload|
  req = payload[:request]
  if req.env['rack.attack.matched'] == "admin"
    Rails.logger.info "[RACK ATTACK] Request to admin: #{req.path} from #{req.remote_ip}"
  end
end
