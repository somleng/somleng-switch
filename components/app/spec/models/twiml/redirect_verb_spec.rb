require "spec_helper"

module TwiML
  RSpec.describe RedirectVerb do
    describe ".parse" do
      it "validates the URL" do
        twiml = <<~TWIML
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Redirect></Redirect>
          </Response>
        TWIML
        redirect_node = TwiMLDocument.new(twiml).twiml.first

        expect { RedirectVerb.parse(redirect_node) }.to raise_error(::Errors::TwiMLError, "<Redirect> must contain a URL")
      end
    end
  end
end
