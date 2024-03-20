require "spec_helper"

module TwiML
  RSpec.describe ConnectVerb do
    describe ".parse" do
      it "parses a <Connect> verb" do
        twiml = <<~TWIML
          <?xml version="1.0" encoding="UTF-8"?>
          <Response>
            <Connect>
              <!-- This is a comment -->
              <Stream url="wss://mystream.ngrok.io/audiostream" />
            </Connect>
          </Response>
        TWIML
        connect_node = TwiMLDocument.new(twiml).twiml.first

        result = ConnectVerb.parse(connect_node)

        expect(result.stream_noun.url).to eq("wss://mystream.ngrok.io/audiostream")
      end

      it "handles nested <Stream> <Parameter> nouns" do
        twiml = <<~TWIML
          <?xml version="1.0" encoding="UTF-8"?>
          <Response>
            <Connect>
              <Stream url="wss://mystream.ngrok.io/audiostream">
                <Parameter name="aCustomParameter" value="aCustomValue that was set in TwiML" />
                <Parameter name="bCustomParameter" value="bCustomValue that was set in TwiML" />
                <!-- Parameter name="bCustomParameter" value="bCustomValue that was set in TwiML" /-->
              </Stream>
            </Connect>
          </Response>
        TWIML
        connect_node = TwiMLDocument.new(twiml).twiml.first

        result = ConnectVerb.parse(connect_node)

        expect(result.stream_noun.parameters).to eq(
          "aCustomParameter" => "aCustomValue that was set in TwiML",
          "bCustomParameter" => "bCustomValue that was set in TwiML"
        )
      end

      it "handles invalid nested <Stream> nouns" do
        twiml = <<~TWIML
          <?xml version="1.0" encoding="UTF-8"?>
          <Response>
            <Connect>
              <Stream url="wss://mystream.ngrok.io/audiostream">
                <Parameter name="aCustomParameter" value="aCustomValue that was set in TwiML" />
                <Foobar name="bCustomParameter" value="bCustomValue that was set in TwiML" />
              </Stream>
            </Connect>
          </Response>
        TWIML
        connect_node = TwiMLDocument.new(twiml).twiml.first

        expect { ConnectVerb.parse(connect_node) }.to raise_error(::Errors::TwiMLError, "<Stream> must only contain <Parameter> nouns")
      end

      it "handles invalid <Parameter> nouns" do
        twiml = <<~TWIML
          <?xml version="1.0" encoding="UTF-8"?>
          <Response>
            <Connect>
              <Stream url="wss://mystream.ngrok.io/audiostream">
                <Parameter foobar="aCustomParameter" value="aCustomValue that was set in TwiML" />
              </Stream>
            </Connect>
          </Response>
        TWIML
        connect_node = TwiMLDocument.new(twiml).twiml.first

        expect { ConnectVerb.parse(connect_node) }.to raise_error(::Errors::TwiMLError, "<Parameter> must have a 'name' and 'value' attribute")
      end

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
    end
  end
end
