class PermissionsGroup
  attr_reader :region_code

  # Bitmask
  # First 6 bits (Region Code)
  # Bit 7 (Symmetric NAT enabled)
  # Bit 8 (Media proxy enabled)

  # Examples
  # 0b00000000 -> Region Code: 0, Symmetric NAT: 0, Media Proxy 0
  # 0b01000000 -> Region Code: 0, Symmetric NAT: 1, Media Proxy 0
  # 0b00000001 -> Region Code: 1, Symmetric NAT: 0, Media Proxy 0

  SYMMETRIC_NAT = 0b01000000
  MEDIA_PROXY = 0b10000000

  def initialize(**options)
    options.transform_keys!(&:to_sym)
    @region_code = options.fetch(:region_code, 0).to_i
    @symmetric_nat_enabled = options.fetch(:symmetric_nat, false).to_s == "true"
    @media_proxy_enabled = options.fetch(:media_proxy, false).to_s == "true"
  end

  def to_i
    region_code | symmetric_nat_flag | media_proxy_flag
  end

  private

  def symmetric_nat_flag
    !!@symmetric_nat_enabled ? SYMMETRIC_NAT : 0
  end

  def media_proxy_flag
    !!@media_proxy_enabled ? MEDIA_PROXY : 0
  end
end
