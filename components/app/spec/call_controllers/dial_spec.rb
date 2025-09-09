require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  describe "<Dial>" do
    let(:parent_call_sid) { "15f55641-7728-4cab-8e2e-8077c4b3c6b4" } # From VCR cassette

    # From: https://www.twilio.com/docs/api/twiml/dial

    # The <Dial> verb connects the current caller to another phone.
    # If the called party picks up, the two parties are connected and can
    # communicate until one hangs up. If the called party does not pick up,
    # if a busy signal is received, or if the number doesn't exist,
    # the dial verb will finish.

    # When the dialed call ends, Twilio makes a GET or POST request
    # to the 'action' URL if provided.
    # Call flow will continue using the TwiML received in response to that request.

    # | Noun         | Description                                                       |
    # | plain text   | A string representing a valid phone number to call.               |
    # | <Number>     | A nested XML element that describes                               |
    # |              | a phone number with more complex attributes.                      |
    # | <Client>     | A nested XML element that describes a Twilio Client connection.   |
    # | <Sip>        | A nested XML element that describes a SIP connection.             |
    # | <Conference> | A nested XML element that describes a conference                  |
    # |              | allowing two or more parties to talk.                             |
    # | <Queue>      | A nested XML element identifying a queue                          |
    # |              | that this call should be connected to.                            |

    it "dials to plain text", :vcr, cassette: :dial do
      controller = build_controller(
        stub_voice_commands: [ :play_audio, { dial: build_dial_status } ],
        call_properties: {
          call_sid: parent_call_sid
        }
      )

      stub_twiml_request(controller, response: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Dial>85516701721</Dial>
          <Play>foo.mp3</Play>
        </Response>
      TWIML

      controller.run

      expect(controller).to have_received(:dial).with(
        include(
          dial_string("85516701721") => hash_including(
            for: 30.seconds,
            from: match(/\A855/),
            headers: hash_including(
              "X-Somleng-CallSid" => be_present,
              "X-Somleng-AccountSid" => be_present
            )
          )
        )
      )
      expect(controller).to have_received(:play_audio).with("foo.mp3")
    end

    it "handles national dialing", :vcr, cassette: :dial_with_national_dialing do
      controller = build_controller(
        stub_voice_commands: [ :play_audio, { dial: build_dial_status } ],
        call_properties: {
          call_sid: parent_call_sid
        }
      )

      stub_twiml_request(controller, response: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Dial>85516701721</Dial>
        </Response>
      TWIML

      controller.run

      expect(controller).to have_received(:dial).with(
        include(
          dial_string("016701721") => hash_including(from: match(/\A0/))
        )
      )
    end

    it "handles different SIP profiles", :vcr, cassette: :dial_to_test_profile do
      controller = build_controller(
        stub_voice_commands: [ { dial: build_dial_status } ],
        call_properties: {
          call_sid: parent_call_sid
        }
      )

      stub_twiml_request(controller, response: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Dial>85516701721</Dial>
        </Response>
      TWIML

      controller.run

      expect(controller).to have_received(:dial).with(
        include(
          dial_string("016701721", profile: "test") => be_a_kind_of(Hash)
        )
      )
    end

    it "dials to <Number>", :vcr, cassette: :dial_multiple do
      controller = build_controller(
        stub_voice_commands: { dial: build_dial_status },
        call_properties: {
          call_sid: parent_call_sid
        }
      )

      stub_twiml_request(controller, response: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Dial>
            <Number>85516701721</Number>
            <Number>855715100860</Number>
            <Number>85510555777</Number>
          </Dial>
        </Response>
      TWIML

      controller.run

      expect(controller).to have_received(:dial).with(
        include(
          dial_string("85516701721") => hash_including(from: match(/\A855/),),
          dial_string("0715100860", profile: "test") => hash_including(from: match(/\A0/)),
          dial_string("85510555777") => hash_including(from: match(/\A855/))
        ),
        any_args
      )
    end

    it "dials to <Sip>", :vcr, cassette: :dial_sip do
      controller = build_controller(
        stub_voice_commands: { dial: build_dial_status },
        call_properties: {
          call_sid: parent_call_sid
        }
      )

      stub_twiml_request(controller, response: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Dial>
            <Sip>sip:alice@sip.example.com</Sip>
          </Dial>
        </Response>
      TWIML

      controller.run

      expect(controller).to have_received(:dial).with(
        include(
          "sofia/nat-gateway/alice@sip.example.com" => hash_including(for: 30.seconds, headers: be_a_kind_of(Hash))
        )
      )
    end

    it "supports callerId", :vcr, cassette: :dial_multiple_with_caller_id do
      controller = build_controller(
        stub_voice_commands: { dial: build_dial_status },
        call_properties: {
          call_sid: parent_call_sid
        }
      )

      stub_twiml_request(controller, response: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Dial callerId="85523238265">
            <Number>85516701721</Number>
            <Number>855715100860</Number>
            <Number>85510555777</Number>
          </Dial>
        </Response>
      TWIML

      controller.run

      expect(controller).to have_received(:dial).with(
        include(
          dial_string("85516701721") => hash_including(from: "85523238265"),
          dial_string("0715100860", profile: "test") => hash_including(from: "023238265"),
          dial_string("85510555777") => hash_including(from: "85523238265")
        )
      )
    end

    describe "Verb Attributes" do
      # From: https://www.twilio.com/docs/api/twiml/gather

      # The <Gather> verb supports the following attributes that modify its behavior:

      # | Attribute Name      | Allowed Values           | Default Value        |
      # | action              | relative or absolute URL | current document URL |
      # | method              | GET, POST                | POST                 |
      # | timeout             | positive integer         | 5 seconds            |
      # | finishOnKey         | any digit, #, *          | #                    |
      # | numDigits           | integer >= 1             | unlimited            |
      # | actionOnEmptyResult | true, false              | false                |
    end

    describe "action" do
      # The 'action' attribute takes a URL as an argument.
      # When the dialed call ends, Twilio will make a GET or POST request to
      # this URL including the parameters below.

      # If you provide an 'action' URL, Twilio will continue the current call after
      # the dialed party has hung up, using the TwiML received
      # in your response to the 'action' URL request.
      # Any TwiML verbs occurring after a which specifies
      # an 'action' attribute are unreachable.

      # If no 'action' is provided, <Dial> will finish and Twilio will move on
      # to the next TwiML verb in the document. If there is no next verb,
      # Twilio will end the phone call.
      # Note that this is different from the behavior of <Record> and <Gather>.
      # <Dial> does not make a request to the current document's URL by default
      # if no 'action' URL is provided.
      # Instead the call flow falls through to the next TwiML verb.

      # Request Parameters

      # "Twilio will pass the following parameters in addition to the standard
      # TwiML Voice request parameters with its request to the 'action' URL:"

      # | Parameter        | Description                                              |
      # | DialCallStatus   | The outcome of the <Dial> attempt.                       |
      # |                  | See the DialCallStatus section below for details.        |
      # | DialCallSid      | The call sid of the new call leg.                        |
      # |                  | This parameter is not sent after dialing a conference.   |
      # | DialCallDuration | The duration in seconds of the dialed call.              |
      # |                  | This parameter is not sent after dialing a conference.   |
      # | RecordingUrl     | The URL of the recorded audio.                           |
      # |                  | This parameter is only sent if record="true" is set      |
      # |                  | on the <Dial> verb, and does not include recordings      |
      # |                  | from the <Record> verb or Record=True on REST API calls. |

      # DialCallStatus Values

      # | Value     | Description                                                               |
      # | completed | The called party answered the call and was connected to the caller.       |
      # | busy      | Twilio received a busy signal when trying to connect to the called party. |
      # | no-answer | The called party did not pick up before the timeout period passed.        |
      # | failed    | Twilio was unable to route to the given phone number.                     |
      # |           | This is frequently caused by dialing                                      |
      # |           | a properly formatted but non-existent phone number.                       |
      # | canceled  | The call was canceled via the REST API before it was answered.            |

      it "POSTS to the action url", :vcr, cassette: :dial do
        outbound_call = build_outbound_call(id: "481f77b9-a95b-4c6a-bbb1-23afcc42c959")
        joins_status = build_dial_join_status(:joined, duration: 23.7)

        controller = build_controller(
          stub_voice_commands: { dial: build_dial_status(:answer, joins: { outbound_call => joins_status }) },
          call_properties: { voice_url: "https://www.example.com/dial.xml" }
        )

        stub_request(:any, "https://www.example.com/dial.xml").to_return(body: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Dial action="https://www.example.com/dial_results.xml">+855 16 701721</Dial>
            <Play>foo.mp3</Play>
          </Response>
        TWIML

        stub_request(:any, "https://www.example.com/dial_results.xml").to_return(body: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Hangup/>
          </Response>
        TWIML

        controller.run

        expect(WebMock).to(have_requested(:post, "https://www.example.com/dial_results.xml").with { |request|
          expect(request.body).to include("DialCallStatus=completed")
          expect(request.body).to include("DialCallSid=481f77b9-a95b-4c6a-bbb1-23afcc42c959")
          expect(request.body).to include("DialCallDuration=23")
        })
      end

      it "handles multiple calls", :vcr, cassette: :dial_multiple do
        joined_outbound_call = build_outbound_call(id: "481f77b9-a95b-4c6a-bbb1-23afcc42c959")
        no_answer_outbound_call = build_outbound_call

        controller = build_controller(
          stub_voice_commands: {
            dial: build_dial_status(
              :answer,
              joins: {
                joined_outbound_call => build_dial_join_status(:joined, duration: 25),
                no_answer_outbound_call => build_dial_join_status(:no_answer)
              }
            )
          },
          call_properties: { voice_url: "https://www.example.com/dial.xml" }
        )

        stub_request(:any, "https://www.example.com/dial.xml").to_return(body: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Dial action="https://www.example.com/dial_results.xml">
              <Number>85516701721</Number>
              <Number>855715100860</Number>
            </Dial>
          </Response>
        TWIML

        stub_request(:any, "https://www.example.com/dial_results.xml").to_return(body: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Hangup/>
          </Response>
        TWIML

        controller.run

        expect(WebMock).to(have_requested(:post, "https://www.example.com/dial_results.xml").with { |request|
          expect(request.body).to include("DialCallStatus=completed")
          expect(request.body).to include("DialCallSid=481f77b9-a95b-4c6a-bbb1-23afcc42c959")
          expect(request.body).to include("DialCallDuration=25")
        })
      end
    end

    describe "method" do
      # The 'method' attribute takes the value 'GET' or 'POST'.
      # This tells Twilio whether to request the 'action' URL via HTTP GET or POST.
      # This attribute is modeled after the HTML form 'method' attribute.
      # 'POST' is the default value.

      it "executes a GET request", :vcr, cassette: :dial do
        controller = build_controller(
          stub_voice_commands: { dial: build_dial_status }
        )

        stub_twiml_request(controller, response: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Dial action="https://www.example.com/dial_results.xml" method="GET">+855 16 701 721</Dial>
          </Response>
        TWIML

        stub_request(:any, %r{www.example.com/dial_results.xml}).to_return(body: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Hangup/>
          </Response>
        TWIML

        controller.run

        expect(WebMock).to have_requested(:get, %r{\Ahttps://www.example.com/dial_results.xml\?.+})
      end
    end

    describe "callerId" do
      # The 'callerId' attribute lets you specify the caller ID that will appear
      # to the called party when Twilio calls. By default,
      # when you put a <Dial> in your TwiML response to Twilio's inbound call request,
      # the caller ID that the dialed party sees is the inbound caller's caller ID.

      # For example, an inbound caller to your Twilio number has the caller ID 1-415-123-4567.
      # You tell Twilio to execute a <Dial> verb to 1-858-987-6543 to handle the inbound call.
      # The called party (1-858-987-6543) will see 1-415-123-4567 as the caller ID
      # on the incoming call.

      # If you are dialing to a <Client>, you can set a client identifier
      # as the callerId attribute. For instance, if you've set up a client
      # for incoming calls and you are dialing to it, you could set the callerId
      # attribute to client:tommy.

      # If you are dialing a phone number from a Twilio Client connection,
      # you must specify a valid phone number as the callerId or the call will fail.

      # You are allowed to change the phone number that the called party
      # sees to one of the following:

      # - either the 'To' or 'From' number provided in Twilio's TwiML request to your app
      # - any incoming phone number you have purchased from Twilio
      # - any phone number you have verified with Twilio

      # | Attribute | Allowed Values                             | Default Value     |
      # | callerId  | a valid phone number, or client identifier | Caller's callerId |
      # |           | if you are dialing a <Client>.             |                   |

      it "sets the callerId", :vcr, cassette: :dial_with_caller_id do
        controller = build_controller(
          stub_voice_commands: { dial: build_dial_status },
          call_properties: {
            call_sid: parent_call_sid
          }
        )

        stub_twiml_request(controller, response: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Dial callerId="85523238265">+85516701721</Dial>
          </Response>
        TWIML

        controller.run

        expect(controller).to have_received(:dial).with(
          include(
            dial_string("85516701721") => hash_including(from: "85523238265")
          )
        )
      end
    end

    describe "timeout" do
      it "handles timeout", :vcr, cassette: :dial_multiple do
        controller = build_controller(
          stub_voice_commands: { dial: build_dial_status }
        )

        stub_twiml_request(controller, response: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Dial timeout="10">85516701721</Dial>
          </Response>
        TWIML

        controller.run

        expect(controller).to have_received(:dial).with(
          include(
            dial_string("85516701721") => hash_including(for: 10.seconds)
          )
        )
      end
    end
  end

  def build_dial_status(result = :answer, joins: {}, calls: Set.new)
    calls << build_outbound_call if calls.empty?
    instance_double(Adhearsion::CallController::DialStatus, result:, joins:, calls:)
  end

  def build_dial_join_status(result = :joined, options = {})
    instance_double(Adhearsion::CallController::Dial::JoinStatus, result:, **options)
  end

  def build_outbound_call(**options)
    instance_double(Adhearsion::OutboundCall, id: SecureRandom.uuid, **options)
  end

  def dial_string(number, profile: "nat-gateway")
    match(%r{sofia/#{profile}/#{number}@.+})
  end
end
