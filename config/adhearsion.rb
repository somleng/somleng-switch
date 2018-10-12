require_relative "../app/models/drb_endpoint"

Adhearsion.config do |config|
  config.core.http.enable = false

  config.adhearsion_drb do |drb|
    drb.shared_object = DrbEndpoint.new
    drb.adhearsion_drb.acl.allow = "all"
  end

  config.twilio do |twilio|
    twilio.rest_api_enabled = "1"
  end
end
