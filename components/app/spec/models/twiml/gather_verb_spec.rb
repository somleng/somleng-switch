require "spec_helper"

module TwiML
  RSpec.describe GatherVerb do
    describe ".parse" do
      it "parses a <Gather> verb" do
        twiml = <<~TWIML
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Gather action="/handle_gather">
              <Say>Hello World</Say>
              <!-- <Say>Hello World</Say> -->
            </Gather>
          </Response>
        TWIML

        gather_node = TwiMLDocument.new(twiml).twiml.first

        result = GatherVerb.parse(gather_node)

        expect(result).to have_attributes(
          action: "/handle_gather"
        )
        expect(result.nested_verbs.size).to eq(1)
        expect(result.nested_verbs.first).to have_attributes(
          name: "Say",
          content: "Hello World"
        )
      end

      it "handles invalid nested verbs" do
        twiml = <<~TWIML
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Gather>
              <Record/>
            </Gather>
          </Response>
        TWIML
        gather_node = TwiMLDocument.new(twiml).twiml.first

        expect { GatherVerb.parse(gather_node) }.to raise_error(::Errors::TwiMLError, "<Record> is not allowed within <Gather>")
      end
    end
  end
end
