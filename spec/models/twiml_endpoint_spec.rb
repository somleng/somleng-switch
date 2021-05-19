require "spec_helper"

RSpec.describe TwiMLEndpoint do
  it "requests a twiml document with HTTP POST" do
    voice_url = "https://example.com/path?b=2&a=1"
    call_data = { foo: :bar }
    auth_token = "auth_token"

    stub_request(:any, voice_url).to_return(body: <<~TWIML)
      <?xml version="1.0" encoding="UTF-8" ?>
      <Response>
        <Say>Hello World</Say>
      </Response>
    TWIML

    endpoint = TwiMLEndpoint.new(auth_token: auth_token)
    twiml = endpoint.request(voice_url, "POST", call_data)

    expect(twiml.to_xml).to eq("<Say>Hello World</Say>")
    expect(WebMock).to(have_requested(:any, voice_url).with { |request|
      validator = Twilio::Security::RequestValidator.new(auth_token)
      expect(validator.validate(voice_url, call_data, request.headers["X-Twilio-Signature"])).to eq(true)
    })
  end

  it "requests a twiml document with HTTP GET" do
    voice_url = "https://example.com/path?b=2&a=1"
    call_data = { foo: :bar }
    auth_token = "auth_token"

    expected_voice_url = "https://example.com/path?b=2&a=1&foo=bar"
    stub_request(:any, expected_voice_url).to_return(body: <<~TWIML)
      <?xml version="1.0" encoding="UTF-8" ?>
      <Response>
        <Say>Hello World</Say>
      </Response>
    TWIML

    endpoint = TwiMLEndpoint.new(auth_token: auth_token)
    twiml = endpoint.request(voice_url, "GET", call_data)

    expect(twiml.to_xml).to eq("<Say>Hello World</Say>")
    expect(WebMock).to(have_requested(:any, expected_voice_url).with { |request|
      validator = Twilio::Security::RequestValidator.new(auth_token)
      expect(validator.validate(expected_voice_url, {}, request.headers["X-Twilio-Signature"])).to eq(true)
    })
  end
end
