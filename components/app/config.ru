require_relative "app/web/application"

run Rack::URLMap.new(
  "/health_checks" => SomlengAdhearsion::Web::HealthChecks,
  "/" => SomlengAdhearsion::Web::API
)
