require "spec_helper"

RSpec.describe Adhearsion::Twilio::ControllerMethods, type: :call_controller do
  describe "<Reject>" do
    # From: https://www.twilio.com/docs/api/twiml/reject

    # The <Reject> verb rejects an incoming call to your Twilio number without billing you.
    # This is very useful for blocking unwanted calls.

    # If the first verb in a TwiML document is <Reject>,
    # Twilio will not pick up the call.
    # The call ends with a status of 'busy' or 'no-answer',
    # depending on the verb's 'reason' attribute.
    # Any verbs after <Reject> are unreachable and ignored.

    # Note that using <Reject> as the first verb in your response is the only way
    # to prevent Twilio from answering a call.
    # Any other response will result in an answered call and your account will be billed.

    it "rejects the call" do
      controller = build_controller(stub_voice_commands: :reject)
      stub_twiml_request(controller, response: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Reject/>
        </Response>
      TWIML

      controller.run

      expect(controller).to have_received(:reject).with(:decline)
    end
  end

  describe "Verb Attributes" do
    # The <Reject> verb supports the following attributes that modify its behavior:

    # | Attribute    | Allowed Values | Default Value              |
    # | reason       | busy, rejected | rejected                   |

    describe "reason" do
      # From: https://www.twilio.com/docs/api/twiml/reject

      # The reason attribute takes the values "rejected" and "busy."
      # This tells Twilio what message to play when rejecting a call.
      # Selecting "busy" will play a busy signal to the caller,
      # while selecting "rejected" will play a standard not-in-service response.
      # If this attribute's value isn't set, the default is "rejected."

      it "rejects the call with a reason" do
        controller = build_controller(stub_voice_commands: :play_audio)
        stub_twiml_request(controller, response: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Reject reason="busy"/>
          </Response>
        TWIML

        controller.run

        expect(controller).to have_received(:reject).with(:busy)
      end
    end
  end
end
