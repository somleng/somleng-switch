require_relative "app_settings"
require_relative "initializers/aws_stubs"

Dir["#{File.dirname(__FILE__)}/../lib/**/*.rb"].sort.each { |f| require f }

EncryptedEnvironmentVariables.new.decrypt

Dir["#{File.dirname(__FILE__)}/**/*.rb"].sort.each { |f| require f }
Dir["#{File.dirname(__FILE__)}/../app/**/*.rb"].sort.each { |f| require f }
