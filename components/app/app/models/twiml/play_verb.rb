require_relative "twiml_verb"
require_relative "loop_attribute"

module TwiML
  class PlayVerb < TwiMLVerb
    def loop
      LoopAttribute.new(attributes["loop"])
    end

    private

    def attributes
      super(verb)
    end
  end
end
