require "bundler/setup"

APP_ENV = ENV["APP_ENV"] || ENV["RACK_ENV"] || "development"
Bundler.require :default, APP_ENV.to_sym

require "sinatra/base"
require "sinatra/json"

require_relative "../../config/app_settings"
require_relative "models/outbound_call"

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

      get "/calls" do
        resource = OutboundCall.new(call_params: params).initiate
        json(resource)
      end
    end
  end
end
