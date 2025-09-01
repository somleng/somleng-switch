class DialString
  EXTERNAL_PROFILE = "external".freeze
  EXTERNAL_NAT_INSTANCE_PROFILE = "alternative-outbound".freeze

  attr_reader :options

  def initialize(options)
    @options = options.symbolize_keys
  end

  def to_s
    "#{format_channel_variables(channel_variables)}sofia/#{external_profile}/#{address}"
  end

  def address
    options.fetch(:address) { routing_parameters.address }
  end

  def format_number(...)
    routing_parameters.format_number(...)
  end

  private

  def routing_parameters
    @routing_parameters ||= RoutingParameters.new(options.fetch(:routing_parameters))
  end

  def external_profile
    routing_parameters.symmetric_latching? ? EXTERNAL_PROFILE : EXTERNAL_NAT_INSTANCE_PROFILE
  end

  def channel_variables
    options.fetch(:channel_variables) { BillingEngineParameters.new(**options.fetch(:billing_parameters)).to_h }
  end

  def format_channel_variables(variables)
    return "" if variables.empty?

    "{#{variables.map { |k, v| "#{k}=#{v}" }.join(",")}}"
  end
end
