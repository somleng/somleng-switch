class RoutingParameters
  attr_reader :destination, :dial_string_prefix, :plus_prefix, :national_dialing,
              :host, :username, :services_client

  def initialize(options)
    options.symbolize_keys!
    @destination = options.fetch(:destination)
    @dial_string_prefix = options.fetch(:dial_string_prefix)
    @plus_prefix = options.fetch(:plus_prefix)
    @national_dialing = options.fetch(:national_dialing)
    @host = options.fetch(:host)
    @username = options.fetch(:username)
    @services_client = options.fetch(:services_client) { Services::Client.new }
  end

  def address
    result = format_number(destination)
    result = username.present? ? client_gateway_address(result) : public_gateway_address(result)
    result.prepend(dial_string_prefix) if dial_string_prefix.present?
    result.prepend("+") if plus_prefix
    result
  end

  def format_number(value)
    result = value.gsub(/\D/, "")
    result = national_dialing && Phony.plausible?(result) ? Phony.format(result, format: :national, spaces: "") : result
    result.gsub(/\D/, "")
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
