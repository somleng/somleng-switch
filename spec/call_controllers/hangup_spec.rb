require "spec_helper"

RSpec.describe Adhearsion::Twilio::ControllerMethods, type: :call_controller do
  describe "<Hangup>" do
    # From: https://www.twilio.com/docs/api/twiml/hangup

    # The <Hangup> verb ends a call.
    # If used as the first verb in a TwiML response it
    # does not prevent Twilio from answering the call and billing your account.
    # The only way to not answer a call and prevent billing is to use the <Reject> verb.

    it "hangs up the call" do
      controller = build_controller(stub_voice_commands: :hangup)
      stub_twiml_request(controller, response: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Hangup/>
        </Response>
      TWIML

      controller.run

      expect(controller).to have_received(:hangup)
    end
  end
end
