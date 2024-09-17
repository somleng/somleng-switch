require "bundler"
Bundler.require(:default)

require_relative "app_settings"
require_relative "initializers/encrypted_environment_variables"

Dir["#{File.dirname(__FILE__)}/../lib/**/*.rb"].each { |f| require f }
Dir["#{File.dirname(__FILE__)}/**/*.rb"].each { |f| require f }
Dir["#{File.dirname(__FILE__)}/../app/**/*.rb"].each { |f| require f }
