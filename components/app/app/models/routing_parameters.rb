class RoutingParameters
  attr_reader :destination, :dial_string_prefix, :plus_prefix, :national_dialing,
              :host, :username, :symmetric_latching, :services_client

  def initialize(options)
    options.symbolize_keys!
    @destination = options.fetch(:destination)
    @dial_string_prefix = options.fetch(:dial_string_prefix)
    @plus_prefix = options.fetch(:plus_prefix)
    @national_dialing = options.fetch(:national_dialing)
    @host = options.fetch(:host)
    @username = options.fetch(:username)
    @symmetric_latching = options.fetch(:symmetric_latching, true)
    @services_client = options.fetch(:services_client) { Services::Client.new }
  end

  def address
    result = format_number(destination).gsub(/\D/, "")
    result = username.present? ? client_gateway_address(result) : public_gateway_address(result)
    result.prepend(dial_string_prefix) if dial_string_prefix.present?
    result.prepend("+") if plus_prefix
    result
  end

  def format_number(value)
    result = value.gsub(/\D/, "")
    result = Phony.format(result, format: :national, spaces: "") if national_dialing && Phony.plausible?(result)
    result = result.gsub(/\D/, "")
    result.prepend("+") if plus_prefix
    result
  end

  def symmetric_latching?
    symmetric_latching
  end

  private

  def client_gateway_address(destination)
    services_client.build_client_gateway_dial_string(
      destination:,
      username:,
    )
  end

  def public_gateway_address(destination)
    "#{destination}@#{host}"
  end
end
