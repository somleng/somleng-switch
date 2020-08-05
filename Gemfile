source "https://rubygems.org"

gem "adhearsion", github: "adhearsion/adhearsion", branch: "develop"
gem "adhearsion-twilio", github: "somleng/adhearsion-twilio"
gem "aws-sdk-sqs"
gem "sentry-raven"
gem "shoryuken"
gem "somleng-twilio_http_client", github: "somleng/somleng-twilio_http_client"

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
