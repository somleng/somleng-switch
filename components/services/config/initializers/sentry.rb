require "sentry-ruby"

Sentry.init do |config|
  config.dsn = AppSettings[:sentry_dsn]
  config.environment = AppSettings.env
end
