require_relative "twiml_node"

module TwiML
  class ConnectVerb < TwiMLNode
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

      def nested_nodes
        node.children
      end

      def stream_noun
        @stream_noun ||= TwiMLNode.parse(nested_nodes.first)
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
