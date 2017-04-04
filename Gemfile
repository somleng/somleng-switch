source 'https://rubygems.org'

ruby(File.read(".ruby-version").strip) if ENV["GEMFILE_LOAD_RUBY_VERSION"].to_i == 1 && File.exist?(".ruby-version")

gem 'adhearsion', :github => "adhearsion/adhearsion"
gem 'adhearsion-twilio', :github => "dwilkie/adhearsion-twilio"
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
end
