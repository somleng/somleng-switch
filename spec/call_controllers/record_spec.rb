require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  describe "<Record>" do
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
      controller = build_controller(
        stub_voice_commands: { record: double(:record_result) },
        call_properties: {
          voice_url: "https://www.example.com/record.xml",
          from: "+85512456869",
          to: "1000"
        }
      )

      first_response = <<~TWIML
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response><Record/></Response>
      TWIML

      second_response = <<~TWIML
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Hangup/>
        </Response>
      TWIML

      stub_twiml_request(controller, response: [first_response, second_response])

      controller.run

      # expect(controller).to have_received(:record).with(start_beep: true)
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

      describe "playBeep" do
        # From: https://www.twilio.com/docs/api/twiml/record

        # The `playBeep`` attribute allows you to toggle between playing a sound before the start of a recording.
        # If you set the value to false, no beep sound will be played.

        it "plays a beep" do
          controller = build_controller(stub_voice_commands: :record)

          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response><Record playBeep="true"/></Response>
          TWIML

          controller.run

          expect(controller).to have_received(:record).with(hash_including(start_beep: true))
        end

        it "does not play a beep" do
          controller = build_controller(stub_voice_commands: :record)

          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response><Record playBeep="false"/></Response>
          TWIML

          controller.run

          expect(controller).to have_received(:record).with(hash_including(start_beep: false))
        end
      end
    end
  end
end
