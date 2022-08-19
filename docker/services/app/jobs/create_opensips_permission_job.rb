class CreateOpenSIPSPermissionJob
  attr_reader :source_ip

  def initialize(source_ip)
    @source_ip = source_ip
  end

  def call
    OpenSIPSAddress.new(ip: source_ip).save!
  end
end
