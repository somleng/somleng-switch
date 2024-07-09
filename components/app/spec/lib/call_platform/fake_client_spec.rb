require "spec_helper"

module CallPlatform
  RSpec.describe FakeClient do
    describe "#create_inbound_call" do
      it "returns a mock <Play> response by default" do
        client = FakeClient.new

        response = client.create_inbound_call(
          to: "+85512345678",
          from: "+855715200987"
        )

        expect(response).to have_attributes(
          twiml: "<Response><Play>https://demo.twilio.com/docs/classic.mp3</Play></Response>",
          account_sid: be_present,
          auth_token: be_present,
          call_sid: be_present,
          default_tts_voice: be_present
        )
      end

      it "returns a mock <Say> response" do
        client = FakeClient.new

        response = client.create_inbound_call(
          to: "1111",
          from: "+855715200987"
        )

        expect(response).to have_attributes(
          twiml: "<Response><Say>Hello World!</Say><Hangup /></Response>"
        )
      end

      it "returns a mock <Connect> response" do
        client = FakeClient.new

        response = client.create_inbound_call(
          to: "2222",
          from: "+855715200987"
        )

        expect(response).to have_attributes(
          twiml: include("<Connect>")
        )
      end
    end

    describe "#create_media_stream" do
      it "returns a mock media stream" do
        client = FakeClient.new

        response = client.create_media_stream(
          url: "wss://example.com/audio",
          phone_call_id: "phone-call-id"
        )

        expect(response).to have_attributes(
          id: be_present
        )
      end
    end
  end
end
