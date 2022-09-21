class RoutingParameters
  attr_reader :destination, :dial_string_prefix, :plus_prefix, :trunk_prefix,
              :host, :username, :services_client

  def initialize(options)
    options.symbolize_keys!
    @destination = options.fetch(:destination)
    @dial_string_prefix = options.fetch(:dial_string_prefix)
    @plus_prefix = options.fetch(:plus_prefix)
    @trunk_prefix = options.fetch(:trunk_prefix)
    @host = options.fetch(:host)
    @username = options.fetch(:username)
    @services_client = options.fetch(:services_client) { Services::Client.new }
  end

  def address
    result = trunk_prefix ? Phony.format(destination, format: :national, spaces: "") : destination
    result = username.present? ? client_gateway_address(result) : public_gateway_address(result)
    result.prepend("+") if plus_prefix
    result
  end

  private

  def client_gateway_address(destination)
    services_client.build_client_gateway_dial_string(
      destination: destination,
      username: username
    )
  end

  def public_gateway_address(destination)
    "#{dial_string_prefix}#{destination}@#{host}"
  end
end
