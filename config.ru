require "sinatra"

set :root, Adhearsion.root

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
