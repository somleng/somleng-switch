class BuildClientGatewayDialString < ApplicationWorkflow
  attr_reader :destination, :client_identifier

  DESTINATION_ADDRESS_FORMAT = "%<destination>s@%<host>s:%<port>s".freeze
  PROXY_ADDRESS_FORMAT = "%<host>s:%<port>s".freeze

  def initialize(destination:, client_identifier:)
    super()
    @destination = destination
    @client_identifier = client_identifier
  end

  def call
    return { destination_address: nil, proxy_address: nil } if location.nil?

    {
      destination_address: format(DESTINATION_ADDRESS_FORMAT, destination:, host: destination_address.host, port: destination_address.port),
      proxy_address: format(PROXY_ADDRESS_FORMAT, host: socket_address.host, port: socket_address.port),
    }
  end

  private

  def socket_address
    parse_socket_address(location.fetch(:socket))
  end

  def destination_address
    parse_socket_address(location.fetch(:received) || location.fetch(:contact))
  end

  def location
    @location ||= OpenSIPSLocation.where(
      username: client_identifier,
      database_connection:
    ).reverse_order(:last_modified).first
  end

  def parse_socket_address(uri)
    URI(uri.sub(/\A(?:sip|udp):/, "sip://").sub(/;.*\z/, ""))
  end

  def database_connection
    @database_connection ||= DatabaseConnections.find(:client_gateway)
  end
end
