require_relative "twiml_verb"

module TwiML
  class ConnectVerb < TwiMLVerb
    VALID_NOUNS = ["Stream"].freeze

    def valid?
      validate_nested_nouns
      validate_noun_attributes

      errors.empty?
    end

    def noun_attributes
      attributes(noun)
    end

    private

    def validate_noun_attributes
      case noun.name
      when "Stream"
        validate_stream_attributes
      end
    end

    def validate_nested_nouns
      return if nested_nouns.one? && VALID_NOUNS.include?(noun.name)

      valid_nouns = VALID_NOUNS.map { |noun| "<#{noun}>" }.join(", ")
      errors.add("<Connect> must contain exactly one of the following nouns: #{valid_nouns}")
    end

    def nested_nouns
      verb.children
    end

    def noun
      nested_nouns.first
    end

    def validate_stream_attributes
      return if URI(noun_attributes["url"].to_s).scheme == "wss"

      errors.add("<Stream> must contain a valid wss 'url' attribute")
    end
  end
end
