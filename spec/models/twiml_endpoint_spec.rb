require "spec_helper"

RSpec.describe TwiMLEndpoint do
  it "requests a twiml document" do
    stub_request(:any, "https://example.com/twiml").to_return(body: <<~TWIML)
      <?xml version="1.0" encoding="UTF-8" ?>
      <Response>
        <Say>Hello World</Say>
      </Response>
    TWIML

    endpoint = TwiMLEndpoint.new(auth_token: "auth_token")
    params = { foo: :bar }
    twiml = endpoint.request("https://example.com/twiml", "GET", params)

    expect(twiml.to_xml).to eq("<Say>Hello World</Say>")
    expect(WebMock).to(have_requested(:any, "https://example.com/twiml").with { |request|
      validator = Twilio::Security::RequestValidator.new("auth_token")
      expect(validator.validate(request.uri, params, request.headers["X-Twilio-Signature"])).to eq(true)
    })
  end
end
