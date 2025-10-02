class DialString
  attr_reader :options

  DEFAULT_SIP_PROFILE = "nat_gateway".freeze

  def initialize(options)
    @options = options.symbolize_keys
  end

  def to_s
    "sofia/#{external_profile}/#{address};fs_path=sip:freeswitch:5060"
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
    options.fetch(:sip_profile, DEFAULT_SIP_PROFILE)
  end
end
