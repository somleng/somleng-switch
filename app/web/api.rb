require_relative "application"

module SomlengAdhearsion
  module Web
    class API < Application
      use Rack::Auth::Basic, "Protected Area" do |username, password|
        username == AppSettings.fetch(:ahn_http_username) && password == AppSettings.fetch(:ahn_http_password)
      end

      post "/calls" do
        call_params = JSON.parse(request.body.read)
        resource = OutboundCall.new(call_params).initiate
        json(id: resource.id)
      end

      delete "/calls/:id" do
        call = Adhearsion.active_calls[params[:id]]
        call.hangup if call.present?

        status 204
      end
    end
  end
end
