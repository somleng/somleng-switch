require "spec_helper"

module TwiML
  RSpec.describe DialVerb do
    describe ".parse" do
      it "handles invalid nested verbs" do
        twiml = <<~TWIML
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Dial>
              <Conference>myteamroom</Conference>
            </Dial>
          </Response>
        TWIML

        dial_node = TwiMLDocument.new(twiml).twiml.first

        expect { DialVerb.parse(dial_node) }.to raise_error(::Errors::TwiMLError, "<Conference> is not allowed within <Dial>")
      end
    end
  end
end
