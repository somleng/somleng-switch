CallPlatform.configure do |config|
  config.host = AppSettings.fetch(:call_platform_host)
  config.username = AppSettings.fetch(:call_platform_username)
  config.password = AppSettings.fetch(:call_platform_password)
  config.stub_responses = !!ENV.fetch("CALL_PLATFORM_STUB_RESPONSES", false).to_s.casecmp("false").nonzero?
end
