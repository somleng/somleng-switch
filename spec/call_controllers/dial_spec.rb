require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  describe "<Dial>" do
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

    it "dials to plain text" do
      controller = build_controller(
        stub_voice_commands: [:play_audio, dial: build_dial_status]
      )

      stub_twiml_request(controller, response: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Dial>+415-123-4567</Dial>
          <Play>foo.mp3</Play>
        </Response>
      TWIML

      controller.run

      expect(controller).to have_received(:dial).with(
        dial_string("+415-123-4567"),
        for: 30.seconds
      )
      expect(controller).to have_received(:play_audio).with("foo.mp3")
    end

    it "dials to <Number>" do
      controller = build_controller(
        stub_voice_commands: { dial: build_dial_status }
      )

      stub_twiml_request(controller, response: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Dial>
            <Number>858-987-6543</Number>
            <Number>415-123-4567</Number>
            <Number>619-765-4321</Number>
          </Dial>
        </Response>
      TWIML

      controller.run

      expect(controller).to have_received(:dial).with(
        {
          dial_string("858-987-6543") => {},
          dial_string("415-123-4567") => {},
          dial_string("619-765-4321") => {}
        },
        any_args
      )
    end

    it "supports callerId" do
      controller = build_controller(
        stub_voice_commands: { dial: build_dial_status }
      )

      stub_twiml_request(controller, response: <<~TWIML)
        <?xml version="1.0" encoding="UTF-8" ?>
        <Response>
          <Dial>
            <Number callerId="2442">858-987-6543</Number>
            <Number callerId="2443">415-123-4567</Number>
            <Number>619-765-4321</Number>
          </Dial>
        </Response>
      TWIML

      controller.run

      expect(controller).to have_received(:dial).with(
        {
          dial_string("858-987-6543") => { from: "2442" },
          dial_string("415-123-4567") => { from: "2443" },
          dial_string("619-765-4321") => {}
        },
        any_args
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

      it "POSTS to the action url" do
        outbound_call = build_outbound_call(id: "481f77b9-a95b-4c6a-bbb1-23afcc42c959")
        joins_status = build_dial_join_status(:joined, duration: 23.7)

        controller = build_controller(
          stub_voice_commands: { dial: build_dial_status(:answer, joins: { outbound_call => joins_status}) },
          call_properties: { voice_url: "https://www.example.com/dial.xml" }
        )

        stub_request(:any, "https://www.example.com/dial.xml").to_return(body: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Dial action="https://www.example.com/dial_results.xml">+415-123-4567</Dial>
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

      it "handles multiple calls" do
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
              <Number>+415-123-4567</Number>
              <Number>+415-123-4568</Number>
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

      it "executes a GET request" do
        controller = build_controller(
          stub_voice_commands: { dial: build_dial_status },
        )

        stub_twiml_request(controller, response: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Dial action="https://www.example.com/dial_results.xml" method="GET">+415-123-4567</Dial>
          </Response>
        TWIML

        stub_request(:any, "https://www.example.com/dial_results.xml").to_return(body: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Hangup/>
          </Response>
        TWIML

        controller.run

        expect(WebMock).to have_requested(:get, "https://www.example.com/dial_results.xml")
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

      it "sets the callerId" do
        controller = build_controller(
          stub_voice_commands: { dial: build_dial_status }
        )

        stub_twiml_request(controller, response: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Dial callerId="2442">+415-123-4567</Dial>
          </Response>
        TWIML

        controller.run

        expect(controller).to have_received(:dial).with(
          dial_string("+415-123-4567"),
          hash_including(from: "2442")
        )
      end
    end

    describe "timeout" do
      it "handles timeout" do
        controller = build_controller(
          stub_voice_commands: { dial: build_dial_status }
        )

        stub_twiml_request(controller, response: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Dial timeout="10">+415-123-4567</Dial>
          </Response>
        TWIML

        controller.run

        expect(controller).to have_received(:dial).with(
          dial_string("+415-123-4567"),
          hash_including(for: 10.seconds)
        )
      end
    end

    describe "ringToneUrl" do
      # Not supported by Twilio

      it "handles a ringToneUrl" do
        controller = build_controller(
          stub_voice_commands: { dial: build_dial_status }
        )

        stub_twiml_request(controller, response: <<~TWIML)
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Dial ringToneUrl="http://api.twilio.com/cowbell.mp3">+415-123-4567</Dial>
          </Response>
        TWIML

        controller.run

        expect(controller).to have_received(:dial).with(
          dial_string("+415-123-4567"),
          hash_including(ringback: "http://api.twilio.com/cowbell.mp3")
        )
      end
    end
  end

  def build_dial_status(result = :answer, joins: {})
    instance_double(Adhearsion::CallController::DialStatus, result: result, joins: joins)
  end

  def build_dial_join_status(result = :joined, options = {})
    instance_double(Adhearsion::CallController::Dial::JoinStatus, result: result, **options)
  end

  def build_outbound_call(options = {})
    instance_double(Adhearsion::OutboundCall, options)
  end

  def dial_string(number)
    Utils.build_dial_string(number)
  end
end
