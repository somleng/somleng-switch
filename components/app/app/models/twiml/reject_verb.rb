require_relative "twiml_node"

module TwiML
  class RejectVerb < TwiMLNode
    def reason
      attributes["reason"]
    end
  end
end
