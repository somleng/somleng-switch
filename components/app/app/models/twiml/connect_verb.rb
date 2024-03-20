require_relative "twiml_node"

module TwiML
  class ConnectVerb < TwiMLNode
    class StreamNoun < TwiMLNode
      class Parser < TwiML::NodeParser
        VALID_NOUNS = ["Parameter"].freeze

        def parse(node)
          super.merge(parameters: build_parameters)
        end

        private

        def valid?
          validate_nested_nouns
          super
        end

        def validate_nested_nouns
          return if nested_nodes.all? { |nested_node| VALID_NOUNS.include?(nested_node.name) }

          errors.add("<Stream> must only contain <Parameter> nouns")
        end

        def build_parameters
          nested_nodes.each_with_object({}) do |nested_node, result|
            parameter_noun = ParameterNoun.parse(nested_node)
            result[parameter_noun.name] = parameter_noun.value
          end
        end
      end

      class << self
        def parse(node)
          super(node, parser: Parser.new)
        end
      end

      attr_reader :parameters

      def initialize(parameters:, **options)
        super(**options)
        @parameters = parameters
      end

      def url
        attributes.fetch("url")
      end
    end

    class ParameterNoun < TwiMLNode
      class Parser < TwiML::NodeParser
        private

        def valid?
          validate_attributes
          super
        end

        def validate_attributes
          return if noun.attributes["name"].present? && noun.attributes["value"].present?

          errors.add("<Parameter> must have a 'name' and 'value' attribute")
        end

        def noun
          @noun ||= TwiMLNode.parse(node)
        end
      end

      class << self
        def parse(node)
          super(node, parser: Parser.new)
        end
      end

      def name
        attributes.fetch("name")
      end

      def value
        attributes.fetch("value")
      end
    end

    class Parser < TwiML::NodeParser
      VALID_NOUNS = ["Stream"].freeze

      def parse(node)
        super.merge(stream_noun:)
      end

      private

      def valid?
        validate_nested_nouns && validate_stream_attributes

        super
      end

      def validate_nested_nouns
        return true if nested_nodes.one? && VALID_NOUNS.include?(nested_nodes.first.name)

        valid_nouns = VALID_NOUNS.map { |noun| "<#{noun}>" }.join(", ")
        errors.add("<Connect> must contain exactly one of the following nouns: #{valid_nouns}")
        false
      end

      def validate_stream_attributes
        return true if url_scheme(stream_noun.attributes["url"]) == "wss"
        return true if url_scheme(ENV.fetch("CALL_PLATFORM_WS_SERVER_URL", nil)) == "ws"

        errors.add("<Stream> must contain a valid wss 'url' attribute")
        false
      end

      def url_scheme(url)
        URI(url.to_s).scheme
      end

      def stream_noun
        @stream_noun ||= StreamNoun.parse(nested_nodes.first)
      end
    end

    class << self
      def parse(node)
        super(node, parser: Parser.new)
      end
    end

    attr_reader :stream_noun

    def initialize(stream_noun:, **options)
      super(**options)
      @stream_noun = stream_noun
    end
  end
end
