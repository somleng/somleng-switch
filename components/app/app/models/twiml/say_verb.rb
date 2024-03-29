require_relative "twiml_node"
require_relative "loop_attribute"

module TwiML
  class SayVerb < TwiMLNode
    def loop
      LoopAttribute.new(attributes["loop"])
    end

    def voice
      attributes["voice"]
    end

    def language
      attributes["language"]
    end
  end
end
