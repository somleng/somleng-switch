module CallPlatform
  class Client
    class InvalidRequestError < StandardError; end

    DialStringResponse = Struct.new(
      :dial_string,
      :nat_supported,
      keyword_init: true
    )

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
        Raven.capture_message("Invalid phone call event", extra: { response_body: response.body })
      end
    end

    def build_dial_string(params)
      json_response = make_request("/services/dial_string", params: params)
      DialStringResponse.new(
        dial_string: json_response.fetch("dial_string"),
        nat_supported: json_response.fetch("nat_supported", true)
      )
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
        api_version: json_response.fetch("api_version")
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
