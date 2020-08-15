require "rack"
require "sinatra"

LOGGING_BLACKLIST = ["/health_checks"].freeze

class FilteredLogger < Rack::CommonLogger
  def call(env)
    log_request?(env) ? super : @app.call(env)
  end

  def log_request?(env)
    !LOGGING_BLACKLIST.include?(env["PATH_INFO"])
  end
end

set :root, Adhearsion.root
disable :logging
use FilteredLogger

get "/" do
  "Hello world!"
end

get "/health_checks" do
  content_type "application/json"
  cache_control :none
  checks = OkComputer::Registry.all
  checks.run

  body(checks.to_json)
  status(checks.success? ? 200 : 500)
end

run Sinatra::Application
