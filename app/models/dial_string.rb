class DialString
  EXTERNAL_PROFILE = "external".freeze
  EXTERNAL_NAT_INSTANCE_PROFILE = "alternative-outbound".freeze

  attr_reader :address, :symmetric_latching

  def initialize(routing_parameters)
    routing_parameters.symbolize_keys!
    @symmetric_latching = routing_parameters.fetch(:symmetric_latching, true).to_s.casecmp("false").nonzero?
    @address = routing_parameters.fetch(:address) { RoutingParameters.new(routing_parameters).address }
  end

  def to_s
    "sofia/#{external_profile}/#{address}"
  end

  private

  def external_profile
    symmetric_latching ? EXTERNAL_PROFILE : EXTERNAL_NAT_INSTANCE_PROFILE
  end
end
