require_relative "twiml_verb"
require_relative "loop_attribute"

module TwiML
  class SayVerb < TwiMLVerb
    def loop
      LoopAttribute.new(attributes["loop"])
    end

    def voice
      attributes["voice"]
    end

    def language
      attributes["language"]
    end

    private

    def attributes
      super(verb)
    end
  end
end
