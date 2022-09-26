require "bundler"
Bundler.setup

require "adhearsion"
require "active_support/all"
Bundler.require(:default, Adhearsion.environment)

I18n.load_path << Dir[File.expand_path("locales/*.yml")]

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "encrypted_credentials"
require "call_platform"
require "services"

require_relative "app_settings"
Dir[__dir__ + "/../app/**/*.rb"].sort.each { |f| require f }
Dir[__dir__ + "/initializers/**/*.rb"].sort.each { |f| require f }

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), "../app/")))
