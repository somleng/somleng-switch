require "bundler/setup"

APP_ENV = ENV["APP_ENV"] || ENV["RACK_ENV"] || "development"
Bundler.require :default, APP_ENV.to_sym

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

      post "/calls" do
        call_params = JSON.parse(request.body.read)
        resource = OutboundCall.new(call_params).initiate
        resource ? json(resource) : json({})
      end
    end
  end
end
