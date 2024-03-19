require_relative "twiml_verb"

module TwiML
  class DialVerb < TwiMLVerb
    VALID_NOUNS = %w[Number Sip].freeze

    def valid?
      validate_nested_nouns

      errors.empty?
    end

    def action
      attributes["action"]
    end

    def method
      attributes["method"]
    end

    def caller_id
      attributes["callerId"]
    end

    def nested_nouns
      verb.children
    end

    def timeout
      attributes.fetch("timeout", 30).to_i
    end

    private

    def validate_nested_nouns
      return if nested_nouns.all? { |nested_noun| VALID_NOUNS.include?(nested_noun.name) || nested_noun.text? }

      invalid_noun = nested_nouns.find { |v| VALID_NOUNS.exclude?(v.name) }
      errors.add("<#{invalid_noun.name}> is not allowed within <Dial>")
    end

    def attributes
      super(verb)
    end
  end
end
