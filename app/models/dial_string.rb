class DialString
  EXTERNAL_PROFILE = "external".freeze
  EXTERNAL_NAT_INSTANCE_PROFILE = "external-nat-instance".freeze

  attr_reader :address, :profile

  def initialize(address, options = {})
    @address = address
    @profile = options.fetch(:nat_supported, true) ? EXTERNAL_PROFILE : EXTERNAL_NAT_INSTANCE_PROFILE
  end

  def to_s
    "sofia/#{profile}/#{address}"
  end
end
