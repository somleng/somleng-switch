class DialString
  EXTERNAL_PROFILE = "external".freeze
  EXTERNAL_NAT_INSTANCE_PROFILE = "alternative-outbound".freeze

  attr_reader :nat_supported, :address, :profile

  def initialize(address, options = {})
    @address = address
    @nat_supported = options.fetch(:nat_supported, true).to_s.casecmp("false").nonzero?
    @profile = @nat_supported ? EXTERNAL_PROFILE : EXTERNAL_NAT_INSTANCE_PROFILE
  end

  def to_s
    "sofia/#{profile}/#{address}"
  end
end
