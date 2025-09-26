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

    OutboundPhoneCallResponse = Data.define(
      :sid,
      :from,
      :account_sid,
      :parent_call_sid,
      :routing_parameters,
      :billing_parameters,
      :address
    )

    RecordingResponse = Struct.new(
      :id,
      :url,
      keyword_init: true
    )

    AudioStreamResponse = Struct.new(
      :id,
      keyword_init: true
    )

    attr_reader :http_client

    def initialize(**options)
      http_client_options = options.fetch(:http_client_options, {})
      @http_client = options.fetch(:http_client) { default_http_client(**http_client_options) }
    end

    def notify_call_event(params)
      notify_request("/services/phone_call_events", params)
    end

    def notify_tts_event(params)
      notify_request("/services/tts_events", params)
    end

    def notify_media_stream_event(params)
      notify_request("/services/media_stream_events", params)
    end

    def create_inbound_call(params)
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

    def create_outbound_calls(params)
      json_response = make_request("/services/outbound_phone_calls", params: params.compact)

      json_response.fetch("phone_calls").map do |phone_call_response|
        OutboundPhoneCallResponse.new(
          sid: phone_call_response.fetch("sid"),
          parent_call_sid: phone_call_response.fetch("parent_call_sid"),
          account_sid: phone_call_response.fetch("account_sid"),
          from: phone_call_response.fetch("from"),
          routing_parameters: phone_call_response.fetch("routing_parameters"),
          billing_parameters: phone_call_response.fetch("billing_parameters"),
          address: phone_call_response.fetch("address")
        )
      end
    end

    def create_recording(params)
      json_response = make_request("/services/recordings", params:)
      RecordingResponse.new(
        id: json_response.fetch("sid")
      )
    end

    def create_media_stream(params)
      json_response = make_request("/services/media_streams", params:)
      AudioStreamResponse.new(
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

    def notify_request(url, params)
      response = http_client.post(url, params.to_json)

      unless response.success?
        Sentry.capture_message("Invalid Request to: #{url}", extra: { response_body: response.body })
      end
    end

    def make_request(uri, http_method: :post, params: {}, headers: {})
      response = http_client.run_request(http_method, uri, params.to_json, headers)

      raise InvalidRequestError, response.body unless response.success?

      JSON.parse(response.body)
    end

    def default_http_client(**options)
      Faraday.new(url: options.fetch(:url, CallPlatform.configuration.host)) do |conn|
        conn.headers["Accept"] = "application/json"
        conn.headers["Content-Type"] = "application/json"

        conn.adapter Faraday.default_adapter

        conn.request(
          :authorization,
          :basic,
          options.fetch(:username, CallPlatform.configuration.username),
          options.fetch(:password, CallPlatform.configuration.password)
        )
      end
    end
  end
end
