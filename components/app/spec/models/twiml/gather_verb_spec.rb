require "spec_helper"

module TwiML
  RSpec.describe GatherVerb do
    describe ".parse" do
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
