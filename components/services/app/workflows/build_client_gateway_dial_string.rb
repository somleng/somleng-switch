class BuildClientGatewayDialString < ApplicationWorkflow
  attr_reader :destination, :client_identifier

  DIAL_STRING_FORMAT = "%<destination>s@%<host>s:%<port>s".freeze
  PROXY_PATH_FORMAT = "fs_path=sip:%<host>s:%<port>s".freeze

  def initialize(destination:, client_identifier:)
    @destination = destination
    @client_identifier = client_identifier
  end

  def call
    {
      dial_string: build_dial_string
    }
  end

  private

  def build_dial_string
    return if location.nil?

    address = format(DIAL_STRING_FORMAT, destination:, host: destination_address.host, port: destination_address.port)
    proxy_path = format(PROXY_PATH_FORMAT, host: socket_address.host, port: socket_address.port)
    [ address, proxy_path ].join(";")
  end

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
