source "https://rubygems.org"

gem "adhearsion", github: "adhearsion/adhearsion", branch: "develop"
gem "aws-sdk-sqs"
gem "okcomputer"
gem "sentry-raven"
gem "sinatra"
gem "sinatra-contrib"

gem "mail"

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
  gem "vcr"
  gem "webmock"
end
