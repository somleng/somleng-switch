require "spec_helper"

RSpec.describe Adhearsion::Twilio::ControllerMethods, type: :call_controller do
  describe "<Gather>" do
    # From: https://www.twilio.com/docs/api/twiml/gather

    # The <Gather> verb collects digits that a caller enters into
    # his or her telephone keypad. When the caller is done entering data,
    # Twilio submits that data to the provided 'action' URL in an HTTP GET or POST request,
    # just like a web browser submits data from an HTML form.

    # If no input is received before timeout, <Gather>
    # falls through to the next verb in the TwiML document.

    # You may optionally nest <Say> and <Play> verbs within a <Gather> verb
    # while waiting for input. This allows you to read menu options to the caller
    # while letting her enter a menu selection at any time.
    # After the first digit is received the audio will stop playing.

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

      describe "action" do
        # From: https://www.twilio.com/docs/api/twiml/gather

        # The action attribute takes an absolute or relative URL as a value.
        # When the caller has finished entering digits
        # Twilio will make a GET or POST request to this URL including the parameters below.
        # If no action is provided, Twilio will by default make a
        # POST request to the current document's URL.

        # After making this request, Twilio will continue the current call
        # using the TwiML received in your response.
        # Keep in mind that by default Twilio will re-request the current document's URL,
        # which can lead to unwanted looping behavior if you're not careful.
        # Any TwiML verbs occuring after a <Gather> are unreachable,
        # unless the caller enters no digits.

        # If the 'timeout' is reached before the caller enters any digits,
        # or if the caller enters the 'finishOnKey' value before entering any other digits,
        # Twilio will not make a request to the 'action' URL but instead
        # continue processing the current TwiML document with the verb immediately
        # following the <Gather>.

        # Request Parameters

        # Twilio will pass the following parameters in addition to the
        # standard TwiML Voice request parameters with its request to the 'action' URL:

        # | Parameter | Description                                                             |
        # | Digits    | The digits the caller pressed, excluding the finishOnKey digit if used. |

        it "POSTS to the current document's URL by default" do
          controller = build_controller(
            stub_voice_commands: { ask: build_input_result("1") },
            metadata: { voice_request_url: "https://www.example.com/gather.xml" }
          )

          first_response = <<~TWIML
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Gather/>
              <Play>foo.mp3</Play>
            </Response>
          TWIML

          second_response = <<~TWIML
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Hangup/>
            </Response>
          TWIML

          stub_twiml_request(controller, response: [first_response, second_response])

          controller.run

          expect(WebMock).to(have_requested(:post, "https://www.example.com/gather.xml").with { |request|
            request.body.include?("Digits=1")
          })
        end

        it "POSTS to an absolute action URL" do
          controller = build_controller(
            stub_voice_commands: { ask: build_input_result("1") },
            metadata: { voice_request_url: "https://www.example.com/gather.xml" }
          )

          stub_request(:any, "https://www.example.com/gather.xml").to_return(body: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Gather action="https://www.example.com/gather_results.xml" />
            </Response>
          TWIML

          stub_request(:any, "https://www.example.com/gather_results.xml").to_return(body: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Hangup/>
            </Response>
          TWIML

          controller.run

          expect(WebMock).to have_requested(:post, "https://www.example.com/gather_results.xml")
        end

        it "POSTS to a relative action URL" do
          controller = build_controller(
            stub_voice_commands: { ask: build_input_result("1") },
            metadata: { voice_request_url: "https://www.example.com/gather.xml" }
          )

          stub_request(:any, "https://www.example.com/gather.xml").to_return(body: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Gather action="/gather_results.xml" />
            </Response>
          TWIML

          stub_request(:any, "https://www.example.com/gather_results.xml").to_return(body: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Hangup/>
            </Response>
          TWIML

          controller.run

          expect(WebMock).to have_requested(:post, "https://www.example.com/gather_results.xml")
        end

        it "falls through the the next verb in the TwiML document if no input is received" do
          controller = build_controller(
            stub_voice_commands: [:play_audio, ask: build_input_result(nil)],
            metadata: { voice_request_url: "https://www.example.com/gather.xml" }
          )

          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Gather/>
              <Play>foo.mp3</Play>
            </Response>
          TWIML

          controller.run

          expect(controller).to have_received(:play_audio)
        end
      end

      describe "method" do
        # From: https://www.twilio.com/docs/api/twiml/gather

        # The method attribute takes the value 'GET' or 'POST'.
        # This tells Twilio whether to request the 'action' URL via HTTP GET or POST.
        # This attribute is modeled after the HTML form 'method' attribute.
        # 'POST' is the default value.

        it "executes a GET request" do
          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather action="https://www.example.com/gather_results.xml" method="GET"/>
          # </Response>

          controller = build_gather_controller(gather_result: "1")
          erb = generate_cassette_erb(
            action: "https://www.example.com/gather_results.xml",
            method_attribute: :get,
            redirect_url: "https://www.example.com/gather_results.xml"
          )

          VCR.use_cassette(:gather_with_action_and_method, erb: erb) do
            controller.run
          end

          results_request = WebMock.requests.last
          expect(results_request.method).to eq(:get)
        end

        it "executes a POST request" do
          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather action="http://localhost:3000/some_other_endpoint.xml" method="POST"/>
          # </Response>

          controller = build_gather_controller(gather_result: "1")
          erb = generate_cassette_erb(
            action: "https://www.example.com/gather_results.xml",
            method_attribute: :post,
            redirect_url: "https://www.example.com/gather_results.xml"
          )

          VCR.use_cassette(:gather_with_action_and_method, erb: erb) do
            controller.run
          end

          results_request = WebMock.requests.last
          expect(results_request.method).to eq(:post)
        end
      end

      describe "timeout" do
        # From: https://www.twilio.com/docs/api/twiml/gather

        # The timeout attribute sets the limit in seconds that Twilio
        # will wait for the caller to press another digit before moving on
        # and making a request to the 'action' URL.
        # For example, if timeout is '10', Twilio will wait ten seconds
        # for the caller to press another key before submitting the previously
        # entered digits to the 'action' URL.
        # Twilio waits until completing the execution of all nested verbs
        # before beginning the timeout period.

        it "defaults to 5s" do
          # From: https://www.twilio.com/docs/api/twiml/gather

          # | Attribute Name | Allowed Values           | Default Value        |
          # | timeout        | positive integer         | 5 seconds            |

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather/>
          # </Response>

          controller = build_gather_controller

          VCR.use_cassette(:gather, erb: generate_cassette_erb) do
            controller.run
          end

          expect(controller).to have_received(:ask) do |_outputs, options|
            expect(options.fetch(:timeout)).to eq(5.seconds)
          end
        end

        it "sets the timeout from the TwiML" do
          # From: https://www.twilio.com/docs/api/twiml/gather

          # "For example, if 'timeout' is '10', Twilio will wait ten seconds
          # for the caller to press another key before submitting the previously
          # entered digits to the 'action' URL."

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather timeout="10"/>
          # </Response>

          controller = build_gather_controller
          erb = generate_cassette_erb(timeout: "10")

          VCR.use_cassette(:gather_with_timeout, erb: erb) do
            controller.run
          end

          expect(controller).to have_received(:ask) do |_outputs, options|
            expect(options.fetch(:timeout)).to eq(10.seconds)
          end
        end
      end

      describe "finishOnKey" do
        # From: https://www.twilio.com/docs/api/twiml/gather

        # The 'finishOnKey' attribute lets you choose one value that submits
        # the received data when entered.
        # For example, if you set 'finishOnKey' to '#' and the user enters '1234#',
        # Twilio will immediately stop waiting for more input when the '#' is received
        # and will submit "Digits=1234" to the 'action' URL.
        # Note that the 'finishOnKey' value is not sent.
        # The allowed values are
        # the digits 0-9, '#' , '*' and the empty string (set 'finishOnKey' to '').
        # If the empty string is used, <Gather> captures all input and no key will
        # end the <Gather> when pressed.
        # In this case Twilio will submit the entered digits to the 'action' URL only
        # after the timeout has been reached.
        # The default 'finishOnKey' value is '#'. The value can only be a single character.

        it "defaults to #" do
          # From: https://www.twilio.com/docs/api/twiml/gather

          # | Attribute Name | Allowed Values           | Default Value        |
          # | finishOnKey    | any digit, #, *          | #                    |

          # "The default 'finishOnKey' value is '#'."

          # "For example, if you set 'finishOnKey' to '#' and the user enters '1234#',
          # Twilio will immediately stop waiting for more input when the '#' is received
          # and will submit "Digits=1234" to the 'action' URL."

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather/>
          # </Response>

          controller = build_gather_controller

          VCR.use_cassette(:gather, erb: generate_cassette_erb) do
            controller.run
          end

          expect(controller).to have_received(:ask) do |_outputs, options|
            expect(options.fetch(:terminator)).to eq("#")
          end
        end

        it "specifying an empty string turns off the terminator" do
          # From: https://www.twilio.com/docs/api/twiml/gather

          # "(set 'finishOnKey' to '')"

          # "If the empty string is used, <Gather> captures all input and no key will
          # end the <Gather> when pressed.
          # In this case Twilio will submit the entered digits to the 'action' URL only
          # after the timeout has been reached."

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather finishOnKey=""/>
          # </Response>

          controller = build_gather_controller
          erb = generate_cassette_erb(finish_on_key: "")

          VCR.use_cassette(:gather_with_finish_on_key, erb: erb) do
            controller.run
          end

          expect(controller).to have_received(:ask) do |_outputs, options|
            expect(options).not_to have_key(:terminator)
          end
        end

        it "sets the finishOnKey from the TwiML" do
          # From: https://www.twilio.com/docs/api/twiml/gather

          # | Attribute Name | Allowed Values           | Default Value        |
          # | finishOnKey    | any digit, #, *          | #                    |

          # "The allowed values are
          # the digits 0-9, '#' , '*' and the empty string (set 'finishOnKey' to '')."

          # "For example, if you set 'finishOnKey' to '*' and the user enters '1234*',
          # Twilio will immediately stop waiting for more input when the '*' is received
          # and will submit "Digits=1234" to the 'action' URL."

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather finishOnKey="*"/>
          # </Response>

          controller = build_gather_controller
          erb = generate_cassette_erb(finish_on_key: "*")

          VCR.use_cassette(:gather_with_finish_on_key, erb: erb) do
            controller.run
          end

          expect(controller).to have_received(:ask) do |_outputs, options|
            expect(options.fetch(:terminator)).to eq("*")
          end
        end

        it "allows specifying a single digit" do
          # From: https://www.twilio.com/docs/api/twiml/gather

          # | Attribute Name | Allowed Values           | Default Value        |
          # | finishOnKey    | any digit, #, *          | #                    |

          # "The allowed values are
          # the digits 0-9, '#' , '*' and the empty string (set 'finishOnKey' to '')."

          # "For example, if you set 'finishOnKey' to '*' and the user enters '1234*',
          # Twilio will immediately stop waiting for more input when the '*' is received
          # and will submit "Digits=1234" to the 'action' URL."

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather finishOnKey="0"/>
          # </Response>

          controller = build_gather_controller
          erb = generate_cassette_erb(finish_on_key: "0")

          VCR.use_cassette(:gather_with_finish_on_key, erb: erb) do
            controller.run
          end

          expect(controller).to have_received(:ask) do |_outputs, options|
            expect(options.fetch(:terminator)).to eq("0")
          end
        end

        xit "handles pressing the finishOnKey before receiving any input" do
          # From: https://www.twilio.com/docs/api/twiml/gather

          # If the caller enters the 'finishOnKey' value before entering any other digits,
          # Twilio will not make a request to the 'action' URL but instead
          # continue processing the current TwiML document with the verb immediately
          # following the <Gather>.

          # Note: It's not directly possible to achieve the Twilio behavior stated here
          # with Adhearsion out of the box. In Adhearsion when using the 'ask' command
          # and pressing the terminator key before any digits have been entered, it will
          # simply repeat the <Say> or <Play> command until the user enters digits or
          # the timeout is reached.

          # No valid test case here...
        end
      end

      describe "numDigits" do
        # From: https://www.twilio.com/docs/api/twiml/gather

        # The 'numDigits' attribute lets you set the number of digits you are expecting,
        # and submits the data to the 'action' URL once the caller enters that number of digits.
        # For example, one might set 'numDigits' to '5' and ask the caller
        # to enter a 5 digit zip code. When the caller enters the fifth digit of '94117',
        # Twilio will immediately submit the data to the 'action' URL.

        it "is unlimited by default" do
          # From: https://www.twilio.com/docs/api/twiml/gather

          # | Attribute Name | Allowed Values           | Default Value        |
          # | numDigits      | integer >= 1             | unlimited            |

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather/>

          # </Response>

          controller = build_gather_controller

          VCR.use_cassette(:gather, erb: generate_cassette_erb) do
            controller.run
          end

          expect(controller).to have_received(:ask) do |_outputs, options|
            expect(options).not_to have_key(:limit)
          end
        end

        it "sets the numDigits from the TwiML" do
          # From: https://www.twilio.com/docs/api/twiml/gather

          # "For example, one might set 'numDigits' to '5' and ask the caller
          # to enter a 5 digit zip code. When the caller enters the fifth digit of '94117',
          # Twilio will immediately submit the data to the 'action' URL."

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather numDigits="5"/>
          # </Response>

          controller = build_gather_controller
          erb = generate_cassette_erb(num_digits: "5")

          VCR.use_cassette(:gather_with_num_digits, erb: erb) do
            controller.run
          end

          expect(controller).to have_received(:ask) do |_outputs, options|
            expect(options.fetch(:limit)).to eq(5)
          end
        end
      end

      describe "actionOnEmptyResult" do
        # actionOnEmptyResult allows you to force <Gather> to send a webhook to the action url
        # even when there is no input.
        # By default, if <Gather> times out while waiting for the input,
        # it will continue on to the next TwiML instruction.

        it "always send to status" do
          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather actionOnEmptyResult="true" action="https://www.example.com/gather_results.xml">
          #     <Say>
          #       Please enter your account number, followed by the pound sign
          #     </Say>
          #   </Gather>
          #   <Play>foo.mp3</Play>
          # </Response>

          controller = build_gather_controller(allow: :play_audio, gather_result: nil)
          erb = generate_cassette_erb(
            action: "https://www.example.com/gather_results.xml",
            redirect_url: "https://www.example.com/gather_results.xml",
            action_on_empty_result: "true"
          )

          VCR.use_cassette(:gather_with_action_on_empty_result, erb: erb) do
            controller.run
          end

          results_request = WebMock.requests.last
          expect(WebMock.requests.count).to eq(2)
          expect(results_request.uri.host).to eq("www.example.com")
          expect(results_request.uri.path).to eq("/gather_results.xml")
        end
      end
    end

    describe "Nested Verbs" do
      it "handles nested <Play>" do
        # From: https://www.twilio.com/docs/api/twiml/gather

        # "After the caller enters digits on the keypad,
        # Twilio sends them in a request to the current URL.
        # We also add a nested <Play> verb.
        # This means that input can be gathered at any time during <Play>."

        # <?xml version="1.0" encoding="UTF-8" ?>
        # <Response>
        #   <Gather>
        #     <Play loop="0">http://api.twilio.com/cowbell.mp3</Play>
        #   </Gather>
        # </Response>

        controller = build_gather_controller
        erb = generate_cassette_erb(
          file_url: "https://api.twilio.com/cowbell.mp3",
          loop: "0"
        )

        VCR.use_cassette(:gather_play, erb: erb) do
          controller.run
        end

        expect(controller).to have_received(:ask) do |*outputs|
          _options = outputs.extract_options!
          expect(outputs).to eq(Array.new(100, "https://api.twilio.com/cowbell.mp3"))
        end
      end

      it "handles nested <Say>" do
        # From: https://www.twilio.com/docs/api/twiml/gather

        # "After the caller enters digits on the keypad,
        # Twilio sends them in a request to the current URL.
        # We also add a nested <Say> verb.
        # This means that input can be gathered at any time during <Say>."

        # <?xml version="1.0" encoding="UTF-8"?>
        # <Response>
        #   <Gather>
        #     <Say voice="woman", language="de" loop="0">
        #       Hello World
        #     </Say>
        #   </Gather>
        # </Response>

        controller = build_gather_controller
        erb = generate_cassette_erb(
          words: "Hello World",
          voice: "woman",
          language: "de",
          loop: "0"
        )

        VCR.use_cassette(:gather_say, erb: erb) do
          controller.run
        end

        expect(controller).to have_received(:ask) do |*outputs|
          options = outputs.extract_options!
          expect(outputs).to eq(Array.new(100, "Hello World"))
          expect(options).to include(name: "woman", language: "de")
        end
      end
    end
  end

  def build_input_result(utterance = nil)
    instance_spy(
      Adhearsion::CallController::Input::Result,
      status: utterance.present? ? :match : :noinput,
      utterance: utterance
    )
  end
end
