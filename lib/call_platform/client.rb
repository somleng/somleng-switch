module CallPlatform
  class Client
    class InvalidPhoneCallError < StandardError; end
    class UnsupportedGatewayError < StandardError; end

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

    def notify_call_event(params)
      response = http_client.post("/services/phone_call_events", params.to_json)

      unless response.success?
        Raven.capture_message("Invalid phone call event", extra: { response_body: response.body })
      end
    end

    def build_dial_string(params)
      response = http_client.post("/services/dial_string", params.to_json)

      raise UnsupportedGatewayError, response.body unless response.success?

      json_response = JSON.parse(response.body)

      DialStringResponse.new(
        dial_string: json_response.fetch("dial_string"),
        nat_supported: json_response.fetch("nat_supported", true)
      )
    end

    def create_call(params)
      response = http_client.post("/services/inbound_phone_calls", params.to_json)

      raise InvalidPhoneCallError, response.body unless response.success?

      json_response = JSON.parse(response.body)
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
