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
        json(CallSerializer.new(resource).to_h)
      end

      delete "/calls/:id" do
        call = Adhearsion.active_calls[params[:id]]
        call.hangup if call.present?

        status 204
      end

      patch "/calls/:id" do
        AppSettings.redis.with do |connection|
          event_handler = CallUpdateEventHandler.new
          request_schema = UpdateCallRequestSchema.new(JSON.parse(request.body.read))

          connection.publish(
            event_handler.channel_for(params[:id]),
            event_handler.build_event(call_id: params[:id], **request_schema.output).serialize
          )
        end

        return status(204)
      end
    end
  end
end
