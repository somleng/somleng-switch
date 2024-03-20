require_relative "node_parser"

module TwiML
  TwiMLNode = Struct.new(:name, :attributes, :content, :text?, keyword_init: true) do
    class << self
      def parse(node, parser: NodeParser.new)
        new(**parser.parse(node))
      end
    end
  end
end
