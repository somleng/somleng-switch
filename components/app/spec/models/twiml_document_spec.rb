require "spec_helper"

RSpec.describe TwiMLDocument do
  it "executes a TwiML document" do
    xml = <<~TWIML
      <?xml version="1.0" encoding="UTF-8" ?>
      <Response>
        <Play>http://api.twilio.com/cowbell.mp3</Play>
      </Response>
    TWIML

    twiml_document = TwiMLDocument.new(xml)

    expect(twiml_document.twiml.first.name).to eq("Play")
  end

  it "handles invalid TwiML with no response element" do
    xml = <<~TWIML
      <?xml version="1.0" encoding="UTF-8" ?>
      <Play>http://api.twilio.com/cowbell.mp3</Play>
    TWIML

    twiml_document = TwiMLDocument.new(xml)

    expect { twiml_document.twiml }.to raise_error(Errors::TwiMLError, "The root element must be the <Response> element")
  end

  it "handles invalid xml" do
    xml = <<~TWIML
      "Foobar"
    TWIML

    twiml_document = TwiMLDocument.new(xml)

    expect { twiml_document.twiml }.to raise_error(Errors::TwiMLError, /Foobar/)
  end
end
