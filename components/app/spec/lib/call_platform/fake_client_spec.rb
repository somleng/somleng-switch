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

      it "returns a mock <Dial> response" do
        client = FakeClient.new

        response = client.create_inbound_call(
          to: "3333",
          from: "+855715200987"
        )

        expect(response).to have_attributes(
          twiml: include("<Dial>")
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

    describe "#create_outbound_calls" do
      it "returns mock outbound calls" do
        client = FakeClient.new

        response = client.create_outbound_calls(
          destinations: [ "85516701999", "855715100999" ],
          parent_call_sid: "0df546d9-3348-48a7-b797-5a18dac477d2",
          from: nil
        )

        expect(response).to contain_exactly(
          have_attributes(
            from: "855715100850",
            parent_call_sid: "0df546d9-3348-48a7-b797-5a18dac477d2",
            routing_parameters: hash_including(
              destination: "85516701999"
            )
          ),
          have_attributes(
            from: "855715100850",
            parent_call_sid: "0df546d9-3348-48a7-b797-5a18dac477d2",
            routing_parameters: hash_including(
              destination: "855715100999"
            )
          )
        )
      end
    end
  end
end
