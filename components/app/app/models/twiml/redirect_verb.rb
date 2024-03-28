require_relative "twiml_node"

module TwiML
  class RedirectVerb < TwiMLNode
    class Parser < TwiML::NodeParser
      def valid?
        validate_url
        super
      end

      def validate_url
        errors.add("<Redirect> must contain a URL") if node.content.blank?
      end
    end

    class << self
      def parse(node)
        super(node, parser: Parser.new)
      end
    end

    def method
      attributes["method"]
    end
  end
end
