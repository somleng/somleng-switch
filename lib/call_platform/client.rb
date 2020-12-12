module CallPlatform
  class Client
    class InvalidPhoneCallError < StandardError; end

    InboundPhoneCallResponse = Struct.new(
      :voice_url,
      :voice_method,
      :account_sid,
      :auth_token,
      :call_sid,
      :direction,
      :api_version,
      keyword_init: true
    )

    def notify_call_event(params)
      response = http_client.post("/services/phone_call_events", params.to_json)

      unless response.success?
        Raven.capture_message("Invalid phone call event", extra: { response_body: response.body })
      end
    end

    def create_call(params)
      response = http_client.post("/services/inbound_phone_calls", params.to_json)

      raise InvalidPhoneCallError, response.body unless response.success?

      json_response = JSON.parse(response.body)
      InboundPhoneCallResponse.new(
        voice_url: json_response.fetch("voice_url"),
        voice_method: json_response.fetch("voice_method"),
        account_sid: json_response.fetch("account_sid"),
        auth_token: json_response.fetch("account_auth_token"),
        call_sid: json_response.fetch("sid"),
        direction: json_response.fetch("direction"),
        api_version: json_response.fetch("api_version")
      )
    end

    private

    def http_client
      @http_client ||= Faraday.new(url: configuration.host) do |conn|
        conn.headers["Accept"] = "application/json"
        conn.headers["Content-Type"] = "application/json"

        conn.adapter Faraday.default_adapter
        conn.basic_auth(configuration.username, configuration.password)
      end
    end

    def configuration
      CallPlatform.configuration
    end
  end
end
