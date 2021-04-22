require "sinatra/base"
require "sinatra/json"

module SomlengAdhearsion
  module Web
    class Application < Sinatra::Base
      set :root, __dir__
      enable :logging

      use Rack::Auth::Basic, "Protected Area" do |username, password|
        username == AppSettings.fetch(:ahn_http_username) && password == AppSettings.fetch(:ahn_http_password)
      end

      configure :development do
        require "sinatra/reloader"

        register Sinatra::Reloader
      end

      configure :production do
        require "skylight/sinatra"

        Skylight.start!(
          file: File.join(__dir__, "../../config/skylight.yml"),
          env: :production
        )
      end

      post "/calls" do
        call_params = JSON.parse(request.body.read)
        resource = OutboundCall.new(call_params).initiate
        json(id: resource.id)
      end
    end
  end
end
