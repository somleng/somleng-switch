class DatabaseConnections
  attr_reader :collection

  Connection = Struct.new(:type, :identifier, :database_connection, keyword_init: true)
  DATABASE_CONNECTIONS = [
    Connection.new(
      identifier: :public_gateway,
      type: :gateway,
      database_connection: DatabaseConnection.new(db_name: ENV.fetch("PUBLIC_GATEWAY_DB_NAME"))
    ),
    Connection.new(
      identifier: :client_gateway,
      type: :gateway,
      database_connection: DatabaseConnection.new(db_name: ENV.fetch("CLIENT_GATEWAY_DB_NAME"))
    )
  ].freeze

  def self.gateways
    DATABASE_CONNECTIONS.find_all { |c| c.type == :gateway }.map(&:database_connection)
  end

  def self.find(identifier)
    DATABASE_CONNECTIONS.find { |c| c.identifier == identifier }.database_connection
  end
end
