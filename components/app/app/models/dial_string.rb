class DialString
  EXTERNAL_PROFILE = "external".freeze
  EXTERNAL_NAT_INSTANCE_PROFILE = "alternative-outbound".freeze

  attr_reader :options

  def initialize(options)
    @options = options.symbolize_keys
  end

  def to_s
    "#{channel_variables}sofia/#{external_profile}/#{address}"
  end

  def address
    options.fetch(:address) { routing_parameters.address }
  end

  def format_number(...)
    routing_parameters.format_number(...)
  end

  private

  def routing_parameters
    @routing_parameters ||= RoutingParameters.new(options)
  end

  def external_profile
    options.fetch(:symmetric_latching, true) ? EXTERNAL_PROFILE : EXTERNAL_NAT_INSTANCE_PROFILE
  end

  def channel_variables
    result = vars.map { |k, v| "#{k}=#{v}" }.join(",")

    return if result.blank?
    "{#{result}}"
  end

  def vars
    options.fetch(:vars, {})
  end
end
