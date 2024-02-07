module CallPlatform
  class FakeClient < Client
    def notify_call_event(params); end
    def notify_tts_event(params); end

    def create_call(params)
      validate_gateway_headers(params)

      twiml = case params.fetch(:to)
              when "1111" then "<Response><Say>Hello World!</Say><Hangup /></Response>"
              else
                "<Response><Play>https://demo.twilio.com/docs/classic.mp3</Play></Response>"
              end

      InboundPhoneCallResponse.new(
        voice_url: nil,
        voice_method: nil,
        twiml: twiml,
        account_sid: SecureRandom.uuid,
        auth_token: SecureRandom.uuid,
        call_sid: SecureRandom.uuid,
        direction: "inbound",
        to: params.fetch(:to),
        from: params.fetch(:from),
        api_version: "2010-04-01",
        default_tts_voice: "Basic.Kal"
      )
    end

    private

    def validate_gateway_headers(params)
      validate_gateway_header(params, :from)
      validate_gateway_header(params, :to)
    end

    def validate_gateway_header(params, key)
      value = params.fetch(key)
      return if value.match?(/\A\+?\d+\z/)

      raise "Invalid parameter #{key}: #{value}. Expected phone number."
    end
  end
end
