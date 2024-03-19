require_relative "twiml_verb"

module TwiML
  class RejectVerb < TwiMLVerb
    def reason
      attributes["reason"]
    end

    private

    def attributes
      super(verb)
    end
  end
end
