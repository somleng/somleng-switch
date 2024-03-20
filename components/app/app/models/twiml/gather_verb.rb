require_relative "twiml_node"
require_relative "node_parser"

module TwiML
  class GatherVerb < TwiMLNode
    FINISH_ON_KEY_PATTERN = /\A(?:\d|\*|\#)\z/
    DEFAULT_FINISH_ON_KEY = "#".freeze

    class Parser < TwiML::NodeParser
      VALID_NESTED_VERBS = %w[Say Play].freeze

      def parse(node)
        super.merge(
          nested_verbs: parse_nested_verbs
        )
      end

      private

      def parse_nested_verbs
        nested_nodes.map do |nested_node|
          case nested_node.name
          when "Say"
            TwiML::SayVerb.parse(nested_node)
          when "Play"
            TwiML::PlayVerb.parse(nested_node)
          end
        end
      end

      def valid?
        validate_nested_verbs
        super
      end

      def validate_nested_verbs
        return if nested_nodes.all? { |nested_node| VALID_NESTED_VERBS.include?(nested_node.name) }

        invalid_node = nested_nodes.find { |v| VALID_NESTED_VERBS.exclude?(v.name) }
        errors.add("<#{invalid_node.name}> is not allowed within <Gather>")
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

    attr_reader :nested_verbs

    def initialize(nested_verbs:, **options)
      super(**options)
      @nested_verbs = nested_verbs
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
  end
end
