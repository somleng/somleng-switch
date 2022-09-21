Services.configure do |config|
  config.function_arn = AppSettings.fetch(:services_function_arn)
end
