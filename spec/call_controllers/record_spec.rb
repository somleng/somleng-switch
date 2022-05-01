require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  describe "<Record>", :vcr, cassette: :recording  do
    # From: https://www.twilio.com/docs/api/twiml/record

    # The <Record> verb records the caller's voice and returns to you the
    # URL of a file containing the audio recording.
    # You can optionally generate text transcriptions of recorded calls by setting
    # the transcribe attribute of the <Record> verb to true.

    # Example 1: Simple Record
    # Twilio will execute the <Record> verb causing the caller
    # to hear a beep and the recording to start.
    # If the caller is silent for more than five seconds,
    # hits the # key, or the recording maxlength time is hit,
    # Twilio will make an HTTP POST request to the default action URL
    # (ie. the current document URL) with the parameters
    # RecordingUrl and RecordingDuration.

    it "records audio" do
      controller = build_call_controller(
        duration: 5000,
        twiml: <<~TWIML
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response><Record/></Response>
        TWIML
      )

      controller.run

      expect(controller).to have_received(:record).with(
        max_duration: 3600,
        final_timeout: 5,
        start_beep: true,
        interruptible: "1234567890*#"
      )
      expect(WebMock).to(have_requested(:post, "https://www.example.com/record.xml").with { |request|
        request.body.include?("RecordingUrl=#{CGI.escape('http://api.lvh.me:3000/2010-04-01/Accounts/38be17be-1d71-4121-9ad6-d75149413229/Calls/0e5dca40-1545-4aa1-9120-fac43c09bc90/Recordings/39cbca96-2634-4c0a-a6c5-2e7c611d200e')}") &&
        request.body.include?("RecordingDuration=5")
      })
    end

    describe "Verb Attributes" do
      # From: https://www.twilio.com/docs/api/twiml/record

      # The <Record> verb supports the following attributes that modify its behavior:

      # | Attribute Name                | Allowed Values                 | Default Value        |
      # |-------------------------------|--------------------------------|----------------------|
      # | action                        | Relative or absolute URL       | current document URL |
      # | method                        | GET, POST                      | POST                 |
      # | timeout                       | Positive integer               | 5                    |
      # | finishOnKey                   | Any digit, #, *                | 1234567890*#         |
      # | maxLength                     | Integer greater than 1         | 3600 (1 hour)        |
      # | playBeep                      | true, false                    | true                 |
      # | trim                          | trim-silence, do-not-trim      | trim-silence         |
      # | recordingStatusCallback       | relative or absolute URL       | None                 |
      # | recordingStatusCallbackMethod | GET, POST                      | POST                 |
      # | recordingStatusCallbackEvent  | in-progress, completed, absent | completed            |
      # | transcribe                    | true, false                    | false                |
      # | transcribeCallback            | Relative or absolute URL       | None                 |

      describe "action" do
        # From: https://www.twilio.com/docs/api/twiml/record

        # The `action` attribute takes a relative or absolute URL as a value. When recording is finished, Twilio will make a GET or POST request to this URL including the parameters below. If no action is provided, <Record> will request the current document’s URL.

        it "handles action" do
          controller = build_call_controller(
            twiml: <<~TWIML
              <?xml version="1.0" encoding="UTF-8" ?>
              <Response><Record action="https://www.example.com/record_results.xml" /></Response>
            TWIML
          )

          stub_request(:any, "https://www.example.com/record_results.xml").to_return(body: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Hangup/>
            </Response>
          TWIML

          controller.run

          expect(WebMock).to(have_requested(:post, "https://www.example.com/record_results.xml"))
        end
      end

      describe "recordingStatusCallback" do
        # From: https://www.twilio.com/docs/api/twiml/record

        # The `recordingStatusCallback` attribute takes a relative or absolute URL as an argument. If a recordingStatusCallback URL is given, Twilio will make a GET or POST request to the specified URL when the recording is available to access.

        it "handles recordingStatusCallback" do
          controller = build_call_controller(
            twiml: <<~TWIML
              <?xml version="1.0" encoding="UTF-8" ?>
              <Response><Record recordingStatusCallback="https://www.example.com/callback" recordingStatusCallbackMethod="GET" /></Response>
            TWIML
          )

          controller.run

          expect(WebMock).to(have_requested(:post, "http://api.lvh.me:3000/services/recordings").with { |request|
            params = JSON.parse(request.body)

            expect(params).to include(
              "status_callback_url" => "https://www.example.com/callback",
              "status_callback_method" => "GET"
            )
          })
        end
      end

      describe "playBeep" do
        # From: https://www.twilio.com/docs/api/twiml/record

        # The `playBeep` attribute allows you to toggle between playing a sound before the start of a recording.
        # If you set the value to false, no beep sound will be played.

        it "plays a beep" do
          controller = build_call_controller(
            twiml: <<~TWIML
              <?xml version="1.0" encoding="UTF-8" ?>
              <Response><Record playBeep="true" /></Response>
            TWIML
          )

          controller.run

          expect(controller).to have_received(:record).with(hash_including(start_beep: true))
        end

        it "does not play a beep" do
          controller = build_call_controller(
            twiml: <<~TWIML
              <?xml version="1.0" encoding="UTF-8" ?>
              <Response><Record playBeep="false" /></Response>
            TWIML
          )

          controller.run

          expect(controller).to have_received(:record).with(hash_including(start_beep: false))
        end
      end

      describe "maxLength" do
        # From: https://www.twilio.com/docs/api/twiml/record

        # The `maxLength` attribute lets you set the maximum length for the recording in seconds. If you set maxLength to 30, the recording will automatically end after 30 seconds of recorded time has elapsed.

        it "handles maxLength" do
          controller = build_call_controller(
            twiml: <<~TWIML
              <?xml version="1.0" encoding="UTF-8" ?>
              <Response><Record maxLength="30" /></Response>
            TWIML
          )

          controller.run

          expect(controller).to have_received(:record).with(hash_including(max_duration: 30))
        end
      end

      describe "timeout" do
        # From: https://www.twilio.com/docs/api/twiml/record

        # The `timeout` attribute tells Twilio to end the recording after a number of seconds of silence has passed. To disable this feature, set timeout to 0. The default is 5 seconds.

        it "handles timeout" do
          controller = build_call_controller(
            twiml: <<~TWIML
              <?xml version="1.0" encoding="UTF-8" ?>
              <Response><Record timeout="10" /></Response>
            TWIML
          )

          controller.run

          expect(controller).to have_received(:record).with(hash_including(final_timeout: 10))
        end
      end

      describe "finishOnKey" do
        # From: https://www.twilio.com/docs/api/twiml/record

        # The `finishOnKey` attribute lets you choose a set of digits that, when entered, end the recording. For example, if you set finishOnKey to # and the caller presses the # key, Twilio will immediately stop recording and submit RecordingUrl, RecordingDuration, and # as parameters in a request to the action URL. The allowed values are the digits 0-9, # and *. The default is 1234567890*# — ie. any key will end the recording. Unlike <Gather>, you may specify more than one character as a finishOnKey value.

        it "handles finishOnKey" do
          controller = build_call_controller(
            twiml: <<~TWIML
              <?xml version="1.0" encoding="UTF-8" ?>
              <Response><Record finishOnKey="123456789" /></Response>
            TWIML
          )

          controller.run

          expect(controller).to have_received(:record).with(hash_including(interruptible: "123456789"))
        end
      end
    end
  end

  def build_call_controller(options)
    controller = build_controller(
      stub_voice_commands: {
        record: instance_double(
          Adhearsion::Rayo::Component::Record,
          recording: instance_double(
            Adhearsion::Rayo::Component::Record::Recording,
            uri: "{profile=s3}http_cache://https://recording.s3.ap-southeast-1.amazonaws.com/9c76f7f6-3aff-4f7b-a76a-0d017b5df900-2.wav",
            duration: options.fetch(:duration, 5000)
          ),
          component_id: "component-id"
        )
      },
      call_properties: {
        call_sid: "0e5dca40-1545-4aa1-9120-fac43c09bc90",
        voice_url: "https://www.example.com/record.xml",
        from: "+85512456869",
        to: "1000"
      }
    )

    second_response = <<~TWIML
      <?xml version="1.0" encoding="UTF-8" ?>
      <Response>
        <Hangup/>
      </Response>
    TWIML

    stub_twiml_request(controller, response: [options.fetch(:twiml), second_response])

    controller
  end
end
