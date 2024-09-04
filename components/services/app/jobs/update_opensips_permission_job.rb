class UpdateOpenSIPSPermissionJob
  attr_reader :source_ip, :group_id

  def initialize(source_ip, options = {})
    @source_ip = source_ip
    @group_id = options.fetch("group_id", 0)
  end

  def call
    OpenSIPSAddress.where(ip: source_ip, database_connection:).update(grp: group_id)
  end

  private

  def database_connection
    DatabaseConnections.find(:public_gateway)
  end
end
