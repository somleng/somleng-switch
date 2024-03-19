require_relative "twiml_verb"

module TwiML
  class GatherVerb < TwiMLVerb
    VALID_NESTED_VERBS = %w[Say Play].freeze
    FINISH_ON_KEY_PATTERN = /\A(?:\d|\*|\#)\z/
    DEFAULT_FINISH_ON_KEY = "#".freeze

    def valid?
      validate_nested_verbs

      errors.empty?
    end

    def timeout
      attributes.fetch("timeout", 5).to_i
    end

    def num_digits
      attributes["numDigits"].to_i if attributes.key?("numDigits")
    end

    def finish_on_key
      value = attributes["finishOnKey"]

      return if value == ""
      return value if FINISH_ON_KEY_PATTERN.match?(value)

      DEFAULT_FINISH_ON_KEY
    end

    def action_on_empty_result?
      attributes["actionOnEmptyResult"] == "true"
    end

    def action
      attributes["action"]
    end

    def method
      attributes["method"]
    end

    def nested_verbs
      nested_nodes.map do |nested_verb|
        case nested_verb.name
        when "Say"
          TwiML::SayVerb.new(nested_verb)
        when "Play"
          TwiML::PlayVerb.new(nested_verb)
        end
      end
    end

    private

    def validate_nested_verbs
      return if nested_nodes.all? { |nested_verb| VALID_NESTED_VERBS.include?(nested_verb.name) }

      invalid_verb = nested_nodes.find { |v| VALID_NESTED_VERBS.exclude?(v.name) }
      errors.add("<#{invalid_verb.name}> is not allowed within <Gather>")
    end

    def nested_nodes
      verb.children
    end

    def attributes
      super(verb)
    end
  end
end
