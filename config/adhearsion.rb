Adhearsion.config do |config|
  # Core Settings
  config.core.http.enable = true
  config.core.type = :xmpp
  config.core.username = AppSettings.fetch(:ahn_core_username)
  config.core.password = AppSettings.fetch(:ahn_core_password)
end
