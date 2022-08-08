module CallPlatform
  class FakeClient < Client
    def notify_call_event(_params); end

    def create_call(params)
      InboundPhoneCallResponse.new(
        voice_url: "https://demo.twilio.com/docs/voice.xml",
        voice_method: "GET",
        twiml: nil,
        account_sid: SecureRandom.uuid,
        auth_token: SecureRandom.uuid,
        call_sid: SecureRandom.uuid,
        direction: "inbound",
        to: params.fetch(:to),
        from: params.fetch(:from),
        api_version: "2010-04-01"
      )
    end
  end
end
