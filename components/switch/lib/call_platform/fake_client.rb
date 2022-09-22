module CallPlatform
  class FakeClient < Client
    def notify_call_event(_params); end

    def create_call(params)
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
        api_version: "2010-04-01"
      )
    end
  end
end
