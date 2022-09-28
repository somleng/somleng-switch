class DeleteOpenSIPSPermissionJob
  attr_reader :source_ip

  def initialize(source_ip)
    @source_ip = source_ip
  end

  def call
    OpenSIPSAddress.where(ip: source_ip, database_connection:).delete
  end

  private

  def database_connection
    DatabaseConnections.find(:public_gateway)
  end
end
