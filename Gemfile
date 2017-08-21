source 'https://rubygems.org'

ruby(File.read(".ruby-version").strip) if ENV["GEMFILE_LOAD_RUBY_VERSION"].to_i == 1 && File.exist?(".ruby-version")

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'adhearsion', :github => "adhearsion/adhearsion", :branch => "develop"
gem 'adhearsion-twilio', :github => "somleng/adhearsion-twilio"
gem 'somleng-twilio_http_client', :github => "somleng/somleng-twilio_http_client"
gem 'eventmachine', "~> 1.0.9"

gem 'adhearsion-drb', :branch => :develop, :github => "dwilkie/adhearsion-drb"

group :development do
  gem 'foreman'
end

group :test do
  gem 'rspec'
  gem 'vcr'
  gem 'webmock'
  gem 'rack-test'
  gem "simplecov", :require => false
  gem "codeclimate-test-reporter", "~> 1.0.0"
end
