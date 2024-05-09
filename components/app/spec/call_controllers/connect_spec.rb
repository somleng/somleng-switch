require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  # from cassette
  describe "<Connect>", :vcr, cassette: :media_stream do
    let(:vcr_call_sid) { "6f362591-ab86-4d1a-b39b-40c87e7929fc" }

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
            stub_voice_commands: :play_audio,
            call_properties: { call_sid: vcr_call_sid }
          )
          stub_twilio_stream(controller)
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

          assert_twilio_stream(controller) do |command|
            expect(command.uuid).to eq(controller.call.id)
            expect(command.url).to eq("wss://mystream.ngrok.io/audiostream")
            expect(command.metadata).to include(
              call_sid: controller.call_properties.call_sid,
              account_sid: controller.call_properties.account_sid,
              stream_sid: "0edc29ef-e45f-408a-89f2-3266ce3352b6" # From VCR Cassette
            )
          end
          expect(controller).to have_received(:play_audio).with("http://api.twilio.com/cowbell.mp3")
        end

        it "handles custom parameters" do
          controller = build_controller(
            call_properties: { call_sid: vcr_call_sid }
          )
          stub_twilio_stream(controller)
          stub_twiml_request(controller, response: <<~TWIML)
            <Response>
              <Connect>
                <Stream url="wss://mystream.ngrok.io/audiostream">
                  <Parameter name="aCustomParameter" value="aCustomValue that was set in TwiML" />
                  <Parameter name="bCustomParameter" value="bCustomValue that was set in TwiML" />
                </Stream>
              </Connect>
            </Response>
          TWIML

          controller.run

          assert_twilio_stream(controller) do |command|
            expect(command.metadata).to include(
              custom_parameters: {
                "aCustomParameter" => "aCustomValue that was set in TwiML",
                "bCustomParameter" => "bCustomValue that was set in TwiML"
              }
            )
          end
        end

        it "handles call url updates" do
          controller = build_controller(
            call_properties: { call_sid: vcr_call_sid }
          )
          call_update_event_handler = CallUpdateEventHandler.new
          stub_twilio_stream(
            controller,
            other_messages: {
              call_update_event_handler.channel_for(controller.call.id) => [
                call_update_event_handler.build_event(
                  call_id: controller.call.id,
                  voice_url: "https://www.example.com/redirect.xml",
                  voice_method: "POST"
                ).serialize
              ]
            }
          )
          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8"?>
            <Response>
              <Connect>
                <Stream url="wss://mystream.ngrok.io/audiostream" />
              </Connect>
              <Play>https://api.twilio.com/cowbell.mp3</Play>
            </Response>
          TWIML

          stub_request(:any, "https://www.example.com/redirect.xml").to_return(body: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Hangup/>
            </Response>
          TWIML

          controller.run

          expect(controller).to have_received(:write_and_await_response).with(an_instance_of(Rayo::Command::TwilioStream::Start))
          expect(controller).to have_received(:write_and_await_response).with(an_instance_of(Rayo::Command::TwilioStream::Stop))
          expect(WebMock).to have_requested(:post, "https://www.example.com/redirect.xml")
        end


        it "handles call twiml updates" do
          controller = build_controller(
            call_properties: { call_sid: vcr_call_sid },
            stub_voice_commands: :play_audio
          )
          call_update_event_handler = CallUpdateEventHandler.new
          stub_twilio_stream(
            controller,
            other_messages: {
              call_update_event_handler.channel_for(controller.call.id) => [
                call_update_event_handler.build_event(
                  call_id: controller.call.id,
                  twiml: "<Response><Play>https://www.example.com/new-audio.mp3</Play></Response>",
                ).serialize
              ]
            }
          )
          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8"?>
            <Response>
              <Connect>
                <Stream url="wss://mystream.ngrok.io/audiostream" />
              </Connect>
              <Play>https://api.twilio.com/cowbell.mp3</Play>
            </Response>
          TWIML

          controller.run

          expect(controller).to have_received(:write_and_await_response).with(an_instance_of(Rayo::Command::TwilioStream::Start))
          expect(controller).to have_received(:write_and_await_response).with(an_instance_of(Rayo::Command::TwilioStream::Stop))
          expect(controller).to have_received(:play_audio).with("https://www.example.com/new-audio.mp3")
          expect(controller).not_to have_received(:play_audio).with("https://api.twilio.com/cowbell.mp3")
        end
      end
    end
  end

  def stub_twilio_stream(controller, with_events: [], **options)
    allow(controller).to receive(:write_and_await_response)

    AppSettings.redis.with do |connection|
      build_twilio_stream_events(Array(with_events), **options).each do |(channel, message)|
        connection.publish_on_subscribe(channel, message)
      end
    end
  end

  def build_twilio_stream_events(events, **options)
    channel_name = options.fetch(:channel_name) { ConnectEventHandler.new.channel_for("*") }
    other_messages = options.fetch(:other_messages, {})

    result = []
    result << [ channel_name, build_twilio_stream_event(event: "connect") ]
    result << [ channel_name, build_twilio_stream_event(event: "start") ]
    Array(events).each { |event| result << [ channel_name, build_twilio_stream_event(**event) ] }
    other_messages.each do |channel, messages|
      messages.each do |message|
        result << [ channel, message ]
      end
    end
    result << [ channel_name, build_twilio_stream_event(event: "disconnect") ]
  end

  def build_twilio_stream_event(event:, **attributes)
    ->(channel) { { event:, streamSid: channel.split(":").last, **attributes }.to_json }
  end

  def assert_twilio_stream(controller, &)
    expect(controller).to have_received(:write_and_await_response, &)
  end
end
