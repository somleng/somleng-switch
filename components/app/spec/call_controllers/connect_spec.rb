require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  describe "<Connect>", :vcr, cassette: :audio_stream do
    # From: https://www.twilio.com/docs/voice/twiml/connect

    # <Connect> is a TwiML verb that works together with nested TwiML nouns to connect
    # Voice calls (over PSTN or SIP) to other Twilio services or external services.

    describe "Nouns" do
      # | Noun           | Description                                     |
      # | -------------- | ----------------------------------------------- |
      # | <Room>         | Connects a call to a Programmable Video Room    |
      # |                | a phone number with more complex attributes.    |
      # | <Siprec>       | Streams a call to a configured SIPREC Connector |
      # | <Stream>       | Starts a bi-directional MediaStream             |
      # | <VirtualAgent> | Connects a call to a Dialogflow VirtualAgent    |

      # Currently only the <Stream> verb is supported

      describe "<Stream>" do
        # From: https://www.twilio.com/docs/voice/twiml/stream
        #
        # The <Stream> instruction allows you to receive raw audio streams
        # from a live phone call over WebSockets in near real-time.

        # Bi-directional Media Streams
        # If you want to send media back to the call,
        # the Stream *must* be bi-directional.
        # To do this initialize the stream using the <Connect> TwiML verb as opposed to the <Start> verb.
        # The <Stream> noun's url attribute must be set to a secure websocket server (wss).

        it "connects to a websockets stream" do
          controller = build_controller(
            call_properties: {
              call_sid: "6f362591-ab86-4d1a-b39b-40c87e7929fc"
            }
          )
          allow(controller).to receive(:execute_component_and_await_completion).and_raise(Adhearsion::Call::Hangup)

          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8"?>
            <Response>
              <Connect>
                <Stream url="wss://mystream.ngrok.io/audiostream" />
              </Connect>
            </Response>
          TWIML

          expect { controller.run }.to raise_error(Adhearsion::Call::Hangup)

          expect(controller).to have_received(:execute_component_and_await_completion) do |component|
            expect(component.uuid).to eq(controller.call.id)
            expect(component.url).to eq("wss://mystream.ngrok.io/audiostream")
            metadata = JSON.parse(component.metadata)
            expect(metadata).to include(
              "call_sid" => controller.call_properties.call_sid,
              "account_sid" => controller.call_properties.account_sid,
              "stream_sid" => be_present
            )
          end
        end

        it "handles custom parameters" do
          controller = build_controller(
            stub_voice_commands: :play_audio,
            call_properties: {
              call_sid: "6f362591-ab86-4d1a-b39b-40c87e7929fc"
            }
          )
          allow(controller).to receive(:execute_component_and_await_completion).and_raise(Adhearsion::Call::Hangup)

          stub_twiml_request(controller, response: <<~TWIML)
            <Response>
              <Play>https://api.twilio.com/cowbell.mp3</Play>
              <Connect>
                <Stream url="wss://mystream.ngrok.io/audiostream">
                  <Parameter name="aCustomParameter" value="aCustomValue that was set in TwiML" />
                  <Parameter name="bCustomParameter" value="bCustomValue that was set in TwiML" />
                </Stream>
              </Connect>
            </Response>
          TWIML

          expect { controller.run }.to raise_error(Adhearsion::Call::Hangup)

          expect(controller).to have_received(:play_audio).with("https://api.twilio.com/cowbell.mp3")
          expect(controller).to have_received(:execute_component_and_await_completion) do |component|
            metadata = JSON.parse(component.metadata)
            expect(metadata).to include(
              "custom_parameters" => {
                "aCustomParameter" => "aCustomValue that was set in TwiML",
                "bCustomParameter" => "bCustomValue that was set in TwiML"
              }
            )
          end
        end
      end
    end
  end
end
