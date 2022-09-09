class CreateOpenSIPSPermissionJob
  attr_reader :source_ip

  def initialize(source_ip)
    @source_ip = source_ip
  end

  def call
    OpenSIPSAddress.new(ip: source_ip, database_connection:).save!
  end

  private

  def database_connection
    DatabaseConnections.find(:public_gateway)
  end
end
