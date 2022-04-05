source "https://rubygems.org"

gem "adhearsion", github: "adhearsion/adhearsion", branch: "develop"
gem "http"
gem "okcomputer"
gem "sentry-raven"
gem "sinatra"
gem "sinatra-contrib", require: false
gem "skylight"

gem "mail"

gem "bigdecimal", "~> 1.4.0" # To support Ruby 2.7 with ActiveSupport 4.2

group :development, :test do
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rspec"
end

group :test do
  gem "rack-test"
  gem "rspec"
  gem "simplecov", require: false
  gem "simplecov-lcov", require: false
  gem "twilio-ruby"
  gem "vcr"
  gem "webmock"
end
