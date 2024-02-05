module TwiML
  class TwiMLVerb
    attr_reader :verb, :errors

    def initialize(verb)
      @verb = verb
      @errors = Errors.new
    end

    private

    def attributes(node)
      node.attributes.transform_values(&:value)
    end
  end
end
