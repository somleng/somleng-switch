require_relative "../app/models/drb_endpoint"

Adhearsion.config do |config|
  # Core Settings
  config.core.http.enable = false

  # DRb Settings
  config.adhearsion_drb.shared_object = DrbEndpoint.new
  config.adhearsion_drb.acl.allow = "all"

  # Twilio Settings
  config.twilio.rest_api_enabled = "1"
end
