source "https://rubygems.org"

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem "adhearsion", github: "adhearsion/adhearsion", branch: "develop"
gem "adhearsion-twilio", github: "somleng/adhearsion-twilio"
gem "somleng-twilio_http_client", github: "somleng/somleng-twilio_http_client"

gem "adhearsion-drb", branch: :develop, github: "dwilkie/adhearsion-drb"

group :test do
  gem "codecov", require: false
  gem "rack-test"
  gem "rspec"
  gem "simplecov", require: false
  gem "vcr"
  gem "webmock"
end
