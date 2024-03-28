require_relative "twiml_node"
require_relative "loop_attribute"

module TwiML
  class PlayVerb < TwiMLNode
    def loop
      LoopAttribute.new(attributes["loop"])
    end
  end
end
