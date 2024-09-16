require "bundler"
Bundler.require(:default)

Dir["#{File.dirname(__FILE__)}/../lib/**/*.rb"].each { |f| require f }

require_relative "app_settings"
require_relative "initializers/aws_stubs"

EncryptedEnvironmentVariables.new.decrypt

Dir["#{File.dirname(__FILE__)}/**/*.rb"].each { |f| require f }
