Services.configure do |config|
  config.function_arn = AppSettings.fetch(:services_function_arn)
  config.function_region = AppSettings.fetch(:services_function_region)
end
