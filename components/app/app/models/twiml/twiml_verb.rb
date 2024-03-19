require_relative "errors"

module TwiML
  class TwiMLVerb
    attr_reader :verb, :errors

    def initialize(verb)
      @verb = verb
      @errors = Errors.new
    end

    def name
      verb.name
    end

    def content
      verb.content
    end

    private

    def attributes(node)
      node.attributes.transform_values(&:value)
    end
  end
end
