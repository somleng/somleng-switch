require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  describe "<Connect>" do
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
          controller = build_controller
          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8"?>
            <Response>
              <Connect>
                <Stream url="wss://mystream.ngrok.io/audiostream" />
              </Connect>
              <Play>http://api.twilio.com/cowbell.mp3</Play>
            </Response>
          TWIML

          controller.run

          expect(controller).not_to have_received(:play_audio)
        end

        it "raises an error if the url is invalid" do
          controller = build_controller
          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8"?>
            <Response>
              <Connect>
                <Stream url="https://mystream.ngrok.io/audiostream" />
              </Connect>
            </Response>
          TWIML

          expect { controller.run }.to raise_error(Errors::TwiMLError, "<Stream> must contain a valid wss 'url' attribute")
        end
      end

      describe "<Room>" do
        it "raises an error" do
          controller = build_controller
          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8"?>
            <Response>
              <Connect>
                <Room>DailyStandup</Room>
              </Connect>
            </Response>
          TWIML

          expect { controller.run }.to raise_error(Errors::TwiMLError, "<Connect> must contain exactly one of the following nouns: <Stream>")
        end
      end
    end
  end
end
