require_relative "twiml_verb"

module TwiML
  class RedirectVerb < TwiMLVerb
    def method
      attributes["method"]
    end

    private

    def attributes
      super(verb)
    end
  end
end
