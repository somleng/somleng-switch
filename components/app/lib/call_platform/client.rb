require "faraday"

module CallPlatform
  class Client
    class InvalidRequestError < StandardError; end

    InboundPhoneCallResponse = Struct.new(
      :voice_url,
      :voice_method,
      :twiml,
      :account_sid,
      :auth_token,
      :call_sid,
      :direction,
      :api_version,
      :to,
      :from,
      :default_tts_voice,
      keyword_init: true
    )

    RecordingResponse = Struct.new(
      :id,
      :url,
      keyword_init: true
    )

    def notify_call_event(params)
      response = http_client.post("/services/phone_call_events", params.to_json)

      unless response.success?
        Sentry.capture_message("Invalid phone call event", extra: { response_body: response.body })
      end
    end

    def notify_tts_event(params)
      response = http_client.post("/services/tts_events", params.to_json)

      unless response.success?
        Sentry.capture_message("Invalid phone call event", extra: { response_body: response.body })
      end
    end

    def build_routing_parameters(params)
      make_request("/services/routing_parameters", params: params)
    end

    def create_call(params)
      json_response = make_request("/services/inbound_phone_calls", params: params)
      InboundPhoneCallResponse.new(
        voice_url: json_response.fetch("voice_url"),
        voice_method: json_response.fetch("voice_method"),
        twiml: json_response.fetch("twiml"),
        account_sid: json_response.fetch("account_sid"),
        auth_token: json_response.fetch("account_auth_token"),
        call_sid: json_response.fetch("sid"),
        direction: json_response.fetch("direction"),
        to: json_response.fetch("to"),
        from: json_response.fetch("from"),
        api_version: json_response.fetch("api_version"),
        default_tts_voice: json_response.fetch("default_tts_voice")
      )
    end

    def create_recording(params)
      json_response = make_request("/services/recordings", params: params)
      RecordingResponse.new(
        id: json_response.fetch("sid")
      )
    end

    def update_recording(recording_id, params)
      json_response = make_request("/services/recordings/#{recording_id}", http_method: :patch, params: params)
      RecordingResponse.new(
        id: json_response.fetch("sid"),
        url: json_response.fetch("url")
      )
    end

    private

    def make_request(uri, http_method: :post, params: {}, headers: {})
      response = http_client.run_request(http_method, uri, params.to_json, headers)

      raise InvalidRequestError, response.body unless response.success?

      JSON.parse(response.body)
    end

    def http_client
      @http_client ||= Faraday.new(url: CallPlatform.configuration.host) do |conn|
        conn.headers["Accept"] = "application/json"
        conn.headers["Content-Type"] = "application/json"

        conn.adapter Faraday.default_adapter

        conn.request(
          :authorization,
          :basic,
          CallPlatform.configuration.username,
          CallPlatform.configuration.password
        )
      end
    end
  end
end
