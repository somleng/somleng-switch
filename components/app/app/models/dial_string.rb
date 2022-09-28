class DialString
  EXTERNAL_PROFILE = "external".freeze
  EXTERNAL_NAT_INSTANCE_PROFILE = "alternative-outbound".freeze

  attr_reader :address, :symmetric_latching

  def initialize(options)
    options.symbolize_keys!
    @symmetric_latching = options.fetch(:symmetric_latching, true)
    @address = options.fetch(:address) { RoutingParameters.new(options).address }
  end

  def to_s
    "sofia/#{external_profile}/#{address}"
  end

  private

  def external_profile
    symmetric_latching ? EXTERNAL_PROFILE : EXTERNAL_NAT_INSTANCE_PROFILE
  end
end
