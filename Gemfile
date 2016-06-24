source 'https://rubygems.org'

ruby(File.read(".ruby-version").strip) if File.exist?(".ruby-version")

gem 'adhearsion', "~> 2.6.2"
gem 'adhearsion-twilio',  :path => "/home/dave/work/contrib/adhearsion-twilio", :github => "dwilkie/adhearsion-twilio"
gem 'eventmachine', "~> 1.0.9"

gem 'adhearsion-drb', :path => "/home/dave/work/contrib/adhearsion-drb", :github => "adhearsion/adhearsion-drb"

group :development do
  gem 'foreman'
end

group :test do
  gem 'rspec'
  gem 'vcr'
  gem 'webmock'
  gem 'rack-test'
end
