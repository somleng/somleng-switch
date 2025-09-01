module CGRates
  class ChannelVariables
    attr_reader :charging_mode, :flags

    DEFAULT_FLAGS = [
      # :resources,
      # :attributes,
      # :sessions,
      # :routes,
      # :thresholds,
      # :stats,
      # :accounts
    ].freeze

    def initialize(**options)
      @charging_mode = options.fetch(:charging_mode, :prepaid)
      @flags = options.fetch(:flags, DEFAULT_FLAGS)
    end

    def to_h
      {
        "cgr_reqtype" => cgr_req_type,
        "cgr_flags" => cgr_flags,
        "cgr_account" => "1234",
        "cgr_subject" => "9876",
        "cgr_destination" => "855716100987"
      }.reject { |_, v| v.blank? }
    end

    private

    def cgr_req_type
      case charging_mode.to_sym
      when :prepaid
        "*prepaid"
      when :postpaid
        "*postpaid"
      else
        raise ArgumentError, "Invalid charging mode: #{charging_mode.inspect}"
      end
    end

    def cgr_flags
      flags.map { |flag| "*#{flag}" }.join(";")
    end
  end
end
