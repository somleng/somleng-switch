Raven.configure do |config|
  config.dsn = AppSettings[:sentry_dsn]
  config.current_environment = Adhearsion.environment
  config.environments = %w[production]
end
