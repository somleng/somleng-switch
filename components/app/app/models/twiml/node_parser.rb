require_relative "errors"
require_relative "../errors"

module TwiML
  class NodeParser
    attr_reader :errors

    def initialize
      @errors = Errors.new
    end

    def parse(node)
      @node = node
      raise(::Errors::TwiMLError, errors.full_messages.to_sentence) unless valid?

      {
        name: node.name,
        attributes: node.attributes.transform_values(&:value),
        content: node.content,
        text?: node.text?
      }
    end

    private

    attr_reader :node

    def valid?
      errors.empty?
    end

    def nested_nodes
      node.children.reject(&:comment?)
    end
  end
end
