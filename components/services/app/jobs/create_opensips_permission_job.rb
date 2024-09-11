class CreateOpenSIPSPermissionJob
  attr_reader :source_ip, :group_id

  def initialize(source_ip, options = {})
    @source_ip = source_ip
    @group_id = options.fetch("group_id", 0)
  end

  def call
    return if OpenSIPSAddress.exists?(ip: source_ip, database_connection:)

    OpenSIPSAddress.new(ip: source_ip, grp: group_id, database_connection:).save!
  end

  private

  def database_connection
    @database_connection ||= DatabaseConnections.find(:public_gateway)
  end
end
