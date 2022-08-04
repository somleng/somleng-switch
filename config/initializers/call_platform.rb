CallPlatform.configure do |config|
  config.host = AppSettings.fetch(:call_platform_host)
  config.username = AppSettings.fetch(:call_platform_username)
  config.password = AppSettings.fetch(:call_platform_password)
  config.stub_responses = true if ENV.key?("CALL_PLATFORM_STUB_RESPONSES")
end
