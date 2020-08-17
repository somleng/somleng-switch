require_relative "app/web/application"

run Rack::URLMap.new(
  "/health_checks" => ->(_) { [200, { "Content-Type" => "text/plain" }, ["Still alive!"]] },
  "/" => SomlengAdhearsion::Web::Application
)
