if ENV.key?("CI")
  require "simplecov"
  require "simplecov-lcov"
  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
  SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
  SimpleCov.start
end

ENV["AHN_ENV"] ||= "test"
ENV["APP_ENV"] ||= "test"

require File.expand_path("../config/environment", __dir__)

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = "examples.txt"
end
