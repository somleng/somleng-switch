Sentry.init do |config|
  config.dsn = AppSettings[:sentry_dsn]
  config.environment = Adhearsion.environment
  config.enabled_environments = %w[production]
end
