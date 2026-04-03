require "sinatra/base"
require "sinatra/json"

module SomlengAdhearsion
  module Web
    class Application < Sinatra::Base
      set :root, __dir__
      enable :logging

      set :host_authorization, { permitted_hosts: [] }

      set :dump_errors, true
      set :show_exceptions, false

      error do
        error_details = env['rack.errors']
        error_details.rewind

        logger = Logger.new($stdout)
        logger.level = AppSettings.fetch(:ahn_core_loglevel)
        logger.error error_details.read

        "Internal Server Error"
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
    end
  end
end
