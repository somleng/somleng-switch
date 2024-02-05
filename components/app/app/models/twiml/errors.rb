module TwiML
  class Errors
    delegate :any?, :empty?, to: :errors

    def initialize
      @errors = []
    end

    def add(message)
      errors << message
    end

    def full_messages
      errors
    end

    private

    attr_reader :errors
  end
end
