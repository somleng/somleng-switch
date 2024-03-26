require_relative "errors"
require_relative "../errors"

module TwiML
  class NodeParser
    attr_reader :options, :errors

    def initialize(**options)
      @options = options
      @errors = Errors.new
    end

    def parse(node)
      @node = node
      raise(::Errors::TwiMLError, errors.full_messages.to_sentence) unless valid?

      {
        name: node.name,
        attributes:,
        content: node.content,
        text?: node.text?
      }
    end

    private

    attr_reader :node

    def valid?
      errors.empty?
    end

    def attributes
      node.attributes.transform_values(&:value)
    end

    def nested_nodes
      node.children.reject(&:comment?)
    end
  end
end
