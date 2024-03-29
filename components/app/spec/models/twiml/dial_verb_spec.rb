require "spec_helper"

module TwiML
  RSpec.describe DialVerb do
    describe ".parse" do
      it "parses a <Dial> verb" do
        twiml = <<~TWIML
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Dial>
              <Number>85516701721</Number>
              <!-- Number>855715100860</Number -->
            </Dial>
          </Response>
        TWIML
        dial_node = TwiMLDocument.new(twiml).twiml.first

        result = DialVerb.parse(dial_node)

        expect(result.nested_nouns.size).to eq(1)
        expect(result.nested_nouns.first).to have_attributes(
          content: "85516701721"
        )
      end

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
