Geocoder.configure(
  ip_lookup: :geoip2,
  geoip2: {
    file: File.join(Rails.root, "db", "GeoLite2-City.mmdb")
  }
)