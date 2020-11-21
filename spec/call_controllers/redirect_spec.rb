require "spec_helper"

describe CallController, type: :call_controller do
  describe "<Redirect>" do
    # From: https://www.twilio.com/docs/api/twiml/redirect

    # The <Redirect> verb transfers control of a call to the TwiML at a different URL.
    # All verbs after <Redirect> are unreachable and ignored.

    it "redirects the call to absolute url" do
      controller = build_controller(call_properties: { voice_request_url: "https://www.example.com/twiml.xml" })

      stub_request(:any, "https://www.example.com/twiml.xml").to_return(body: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Redirect>https://www.example.com/redirect.xml</Redirect>
          <Play>foo.mp3</Play>
        </Response>
      TWIML

      stub_request(:any, "https://www.example.com/redirect.xml").to_return(body: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Hangup/>
        </Response>
      TWIML

      controller.run

      expect(WebMock).to have_requested(:post, "https://www.example.com/redirect.xml")
    end

    it "redirects the call to relative url" do
      controller = build_controller(call_properties: { voice_request_url: "https://www.example.com/twiml.xml" })

      stub_request(:any, "https://www.example.com/twiml.xml").to_return(body: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Redirect>/redirect.xml</Redirect>
          <Play>foo.mp3</Play>
        </Response>
      TWIML

      stub_request(:any, "https://www.example.com/redirect.xml").to_return(body: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Hangup/>
        </Response>
      TWIML

      controller.run

      expect(WebMock).to have_requested(:post, "https://www.example.com/redirect.xml")
    end

    describe "Verb Attributes" do
      # The <Redirect> verb supports the following attributes that modify its behavior:

      # | Attribute Name | Allowed Values | Default Value |
      # | method         | GET, POST      | POST          |

      describe "method" do
        it "executes a GET request" do
          controller = build_controller(call_properties: { voice_request_url: "https://www.example.com/twiml.xml" })

          stub_request(:any, "https://www.example.com/twiml.xml").to_return(body: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Redirect method="GET">https://www.example.com/redirect.xml</Redirect>
              <Play>foo.mp3</Play>
            </Response>
          TWIML

          stub_request(:any, "https://www.example.com/redirect.xml").to_return(body: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Hangup/>
            </Response>
          TWIML

          controller.run

          expect(WebMock).to have_requested(:get, "https://www.example.com/redirect.xml")
        end
      end
    end
  end
end
