require "spec_helper"

module TwiML
  RSpec.describe ConnectVerb do
    describe ".parse" do
      it "handles invalid nested nouns" do
        twiml = <<~TWIML
          <?xml version="1.0" encoding="UTF-8"?>
          <Response>
            <Connect>
              <Room>DailyStandup</Room>
            </Connect>
          </Response>
        TWIML
        connect_node = TwiMLDocument.new(twiml).twiml.first

        expect { ConnectVerb.parse(connect_node) }.to raise_error(::Errors::TwiMLError, "<Connect> must contain exactly one of the following nouns: <Stream>")
      end

      it "handles invalid stream URLs" do
        twiml = <<~TWIML
          <?xml version="1.0" encoding="UTF-8"?>
          <Response>
            <Connect>
              <Stream url="https://mystream.ngrok.io/audiostream" />
            </Connect>
          </Response>
        TWIML
        connect_node = TwiMLDocument.new(twiml).twiml.first

        expect { ConnectVerb.parse(connect_node) }.to raise_error(::Errors::TwiMLError, "<Stream> must contain a valid wss 'url' attribute")
      end
    end
  end
end
