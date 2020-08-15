require_relative "app_settings"

Adhearsion.config do |config|
  # Core Settings
  config.core.http.enable = true
  config.core.type = :xmpp
  config.core.username = AppSettings.fetch(:ahn_core_username)
  config.core.password = AppSettings.fetch(:ahn_core_password)
  config.core.host = AppSettings.fetch(:ahn_core_host)
  config.core.port = AppSettings.fetch(:ahn_core_port)

  # Twilio Settings
  config.twilio.rest_api_enabled = "1"
end
