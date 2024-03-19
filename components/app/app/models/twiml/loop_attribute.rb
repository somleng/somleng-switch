module TwiML
  class LoopAttribute
    MAX_LOOP = 100

    attr_reader :value

    def initialize(value)
      @value = value
    end

    def times
      return MAX_LOOP.times if value.to_s == "0"

      [(value || 1).to_i, MAX_LOOP].min.times
    end
  end
end
