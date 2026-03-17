CallPlatform.configure do |config|
  config.host = AppSettings.fetch(:call_platform_host)
  config.username = AppSettings.fetch(:call_platform_username)
  config.password = AppSettings.fetch(:call_platform_password)
end
