require "sinatra/base"
require "sinatra/json"

module SomlengAdhearsion
  module Web
    class Application < Sinatra::Base
      set :root, __dir__
      enable :logging

      set :host_authorization, { permitted_hosts: [] }

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
    end
  end
end
