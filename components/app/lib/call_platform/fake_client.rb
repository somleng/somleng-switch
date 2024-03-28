module CallPlatform
  class FakeClient < Client
    def notify_call_event(params); end
    def notify_tts_event(params); end
    def notify_media_stream_event(params); end

    TestNumber = Struct.new(:number, :twiml_response, :voice_url, :voice_method, keyword_init: true)
    DEFAULT_TEST_NUMBER = TestNumber.new(twiml_response: "<Response><Play>https://demo.twilio.com/docs/classic.mp3</Play></Response>").freeze

    class ConnectTestNumberWithTwiMLResponse < TestNumber
      def twiml_response
        <<~TWIML
        <Response>
          <Connect>
            <!-- This is a comment -->
            <Stream url=\"#{connect_ws_server_url}\">
              <Parameter name=\"aCustomParameter\" value=\"aCustomValue that was set in TwiML\" />
            </Stream>
          </Connect>
          <Play>https://www2.cs.uic.edu/~i101/SoundFiles/taunt.wav</Play>
        </Response>
        TWIML
      end

      private

      def connect_ws_server_url
        ENV.fetch("CONNECT_WS_SERVER_URL", "wss://example.com")
      end
    end

    TEST_NUMBERS = [
      TestNumber.new(number: "1111", twiml_response: "<Response><Say>Hello World!</Say><Hangup /></Response>"),
      ConnectTestNumberWithTwiMLResponse.new(number: "2222")
    ].freeze

    def create_call(params)
      validate_gateway_headers(params)

      test_number = find_test_number(params.fetch(:to))

      InboundPhoneCallResponse.new(
        voice_url: test_number.voice_url,
        voice_method: test_number.voice_method,
        twiml: test_number.twiml_response,
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

    def create_media_stream(**)
      AudioStreamResponse.new(id: SecureRandom.uuid)
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

    def find_test_number(to)
      TEST_NUMBERS.find(-> { DEFAULT_TEST_NUMBER }) { |test_number| test_number.number == to }
    end
  end
end
