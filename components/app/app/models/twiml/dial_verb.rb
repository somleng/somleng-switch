require_relative "twiml_node"

module TwiML
  class DialVerb < TwiMLNode
    class Parser < TwiML::NodeParser
      VALID_NOUNS = %w[Number Sip].freeze

      def parse(node)
        super.merge(
          nested_nouns: parse_nested_nouns
        )
      end

      private

      def parse_nested_nouns
        nested_nodes.map do |nested_node|
          TwiMLNode.parse(nested_node)
        end
      end

      def valid?
        validate_nested_nouns
        super
      end

      def validate_nested_nouns
        return if nested_nodes.all? { |nested_node| VALID_NOUNS.include?(nested_node.name) || nested_node.text? }

        invalid_node = nested_nodes.find { |v| VALID_NOUNS.exclude?(v.name) }
        errors.add("<#{invalid_node.name}> is not allowed within <Dial>")
      end

      def nested_nodes
        node.children
      end
    end

    class << self
      def parse(node)
        super(node, parser: Parser.new)
      end
    end

    attr_reader :nested_nouns

    def initialize(nested_nouns:, **options)
      super(**options)
      @nested_nouns = nested_nouns
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

    def timeout
      attributes.fetch("timeout", 30).to_i
    end
  end
end
