require "spec_helper"

RSpec.describe Adhearsion::Twilio::ControllerMethods, type: :call_controller do
  describe "<Play>" do
    # From: https://www.twilio.com/docs/api/twiml/play

    # "The <Play> verb plays an audio file back to the caller.
    # Twilio retrieves the file from a URL that you provide."

    describe "Nouns" do
      # From: https://www.twilio.com/docs/api/twiml/play

      # The "noun" of a TwiML verb is the stuff nested within the verb
      # that's not a verb itself; it's the stuff the verb acts upon.

      # These are the nouns for <Play>:

      # | Noun        | Description                                                                |
      # | plain text  | The URL of an audio file that Twilio will retrieve and play to the caller. |

      it "plays audio" do
        controller = build_controller(stub_voice_commands: :play_audio)
        stub_twiml_request(controller, response: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Play>http://api.twilio.com/cowbell.mp3</Play>
          </Response>
        TWIML

        controller.run

        expect(controller).to have_received(:play_audio).with("http://api.twilio.com/cowbell.mp3")
      end
    end

    describe "Verb Attributes" do
      # From: https://www.twilio.com/docs/api/twiml/play

      # The <Play> verb supports the following attributes that modify its behavior:

      # | Attribute Name | Allowed Values | Default Value |
      # | loop           | integer >= 0   | 1             |

      describe "loop" do
        # From: https://www.twilio.com/docs/api/twiml/play

        # The 'loop' attribute specifies how many times the audio file is played.
        # The default behavior is to play the audio once.
        # Specifying '0' will cause the the <Play> verb to loop until the call is hung up.

        it "loops n times when n is specified" do
          controller = build_controller(stub_voice_commands: :play_audio)
          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Play loop="5">http://api.twilio.com/cowbell.mp3</Play>
            </Response>
          TWIML

          controller.run

          expect(controller).to have_received(:play_audio).exactly(5).times
        end
      end
    end
  end
end
