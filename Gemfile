source "https://rubygems.org"

gem "adhearsion", github: "adhearsion/adhearsion", branch: "develop"
gem "http"
gem "okcomputer"
gem "sentry-raven"
gem "sinatra"
gem "sinatra-contrib", require: false
gem "skylight"

gem "mail"
gem "net-smtp" # https://github.com/mikel/mail/pull/1439

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
  gem "vcr", github: "vcr/vcr" # https://github.com/vcr/vcr/pull/907#issuecomment-1001650068
  gem "webmock"
end
