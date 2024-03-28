require_relative "application"

module SomlengAdhearsion
  module Web
    class HealthChecks < Application
      error OkComputer::Registry::CheckNotFound do
        halt(404, env["sinatra.error"].message)
      end

      get "/" do
        checks = OkComputer::Registry.all
        checks.run
        respond_with(checks)
      end

      get "/:check" do
        check = OkComputer::Registry.fetch(params[:check])
        check.run
        respond_with(check)
      end

      def respond_with(checks)
        status_code = checks.success? ? 200 : 500
        halt(status_code, { "Content-Type" => "text/plain" }, checks.to_text)
      end
    end
  end
end
