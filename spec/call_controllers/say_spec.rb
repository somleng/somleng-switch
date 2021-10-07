require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  describe "<Say>" do
    # https://www.twilio.com/docs/api/twiml/say

    # The <Say> verb converts text to speech that is read back to the caller.
    # <Say> is useful for development or saying dynamic text that is difficult to pre-record.

    describe "Nouns" do
      # From: https://www.twilio.com/docs/api/twiml/say

      # The "noun" of a TwiML verb is the stuff nested within the verb
      # that's not a verb itself; it's the stuff the verb acts upon.
      # These are the nouns for <Say>:

      # | Noun        | Description                              |
      # | plain text  | The text Twilio will read to the caller. |
      # |             | Limited to 4KB (4,000 ASCII characters)  |

      it "outputs SSML" do
        controller = build_controller(stub_voice_commands: :say)
        stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <!-- Handles whitespace -->
            <Response>
            <!-- Test Comment -->
            <Say>Hola, buen día</Say>
          </Response>
        TWIML

        controller.run

        expect(controller).to have_received(:say) do |ssml|
          expect(ssml).to be_a(RubySpeech::SSML::Speak)
          expect(ssml.text).to eq("Hola, buen día.")
          expect(ssml.to_xml).to include("Hola, buen día.")
        end
      end
    end

    describe "Verb Attributes" do
      # From: https://www.twilio.com/docs/api/twiml/say

      # The <Say> verb supports the following attributes that modify its behavior:

      # | Attribute Name | Allowed Values            | Default Value |
      # | voice          | man, woman                | man           |
      # | language       | en, en-gb, es, fr, de, it | en            |
      # | loop           | integer >= 0              | 1             |

      describe "voice" do
        # From: https://www.twilio.com/docs/api/twiml/say

        # The 'voice' attribute allows you to choose
        # a male or female voice to read text back. The default value is 'man'.

        # | Attribute Name | Allowed Values | Default Value |
        # | voice          | man, woman     | man           |

        it "defaults to man" do
          controller = build_controller(stub_voice_commands: :say)
          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Say>Hello World</Say>
            </Response>
          TWIML

          controller.run

          expect(controller).to have_received(:say) do |ssml|
            expect(fetch_ssml_attribute(ssml, :name)).to eq("man")
          end
        end

        it "sets a custom voice" do
          controller = build_controller(stub_voice_commands: :say)
          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Say voice="woman">Hello World</Say>
            </Response>
          TWIML

          controller.run

          expect(controller).to have_received(:say) do |ssml|
            expect(fetch_ssml_attribute(ssml, :name)).to eq("woman")
          end
        end
      end

      describe "language" do
        # From: https://www.twilio.com/docs/api/twiml/say

        # The 'language' attribute allows you pick a voice with a
        # specific language's accent and pronunciations.
        # Twilio currently supports English with an American accent (en),
        # English with a British accent (en-gb), Spanish (es), French (fr),
        # Italian (it), and German (de).
        # The default is English with an American accent (en).

        # Note: this behaviour differs from Twilio.
        # The language option is not yet supported in adhearsion-twilio
        # so the option is ignored

        it "sets the language to en by default" do
          controller = build_controller(stub_voice_commands: :say)
          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Say>Hello World</Say>
            </Response>
          TWIML

          controller.run

          expect(controller).to have_received(:say) do |ssml|
            expect(fetch_ssml_attribute(ssml, :lang)).to eq("en")
          end
        end

        it "sets the language when specifying the language attribute" do
          controller = build_controller(stub_voice_commands: :say)
          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Say language="pt-BR">Hello World</Say>
            </Response>
          TWIML

          controller.run

          expect(controller).to have_received(:say) do |ssml|
            expect(fetch_ssml_attribute(ssml, :lang)).to eq("pt-BR")
          end
        end
      end

      describe "loop" do
        # From: https://www.twilio.com/docs/api/twiml/say

        # The 'loop' attribute specifies how many times you'd like the text repeated.
        # The default is once.
        # Specifying '0' will cause the <Say> verb to loop until the call is hung up.

        it "loops until hung up if 0 is specified" do
          controller = build_controller(stub_voice_commands: :say)
          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Say loop="0">Hello World</Say>
            </Response>
          TWIML

          controller.run

          expect(controller).to have_received(:say).exactly(100).times
        end

        it "loops n times when n is specified" do
          controller = build_controller(stub_voice_commands: :say)
          stub_twiml_request(controller, response: <<~TWIML)
            <?xml version="1.0" encoding="UTF-8" ?>
            <Response>
              <Say loop="5">Hello World</Say>
            </Response>
          TWIML

          controller.run

          expect(controller).to have_received(:say).exactly(5).times
        end
      end
    end
  end

  def fetch_ssml_attribute(ssml, key)
    ssml.voice.children.first.attributes.fetch(key.to_s).value
  end
end
