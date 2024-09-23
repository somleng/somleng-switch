require "sentry-ruby"

Sentry.init do |config|
  config.dsn = AppSettings[:sentry_dsn]
  config.environment = AppSettings.env
  config.debug = true
  config.background_worker_threads = 0
end
