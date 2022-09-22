class CreateOpenSIPSPermissionJob
  attr_reader :source_ip

  def initialize(source_ip)
    @source_ip = source_ip
  end

  def call
    return if OpenSIPSAddress.exists?(ip: source_ip, database_connection:)

    OpenSIPSAddress.new(ip: source_ip, database_connection:).save!
  end

  private

  def database_connection
    @database_connection ||= DatabaseConnections.find(:public_gateway)
  end
end
