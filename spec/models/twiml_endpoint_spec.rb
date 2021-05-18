require "spec_helper"

RSpec.describe TwiMLEndpoint do
  it "requests a twiml document" do
    voice_url = "https://example.com/path?foo=bar&buzz=bizz"
    params = { foo: :bar }
    auth_token = "auth_token"

    stub_request(:any, voice_url).to_return(body: <<~TWIML)
      <?xml version="1.0" encoding="UTF-8" ?>
      <Response>
        <Say>Hello World</Say>
      </Response>
    TWIML

    endpoint = TwiMLEndpoint.new(auth_token: auth_token)
    twiml = endpoint.request(voice_url, "POST", params)

    expect(twiml.to_xml).to eq("<Say>Hello World</Say>")
    expect(WebMock).to(have_requested(:any, voice_url).with { |request|
      validator = Twilio::Security::RequestValidator.new(auth_token)
      expect(validator.validate(request.uri, params, request.headers["X-Twilio-Signature"])).to eq(true)
    })
  end
end
