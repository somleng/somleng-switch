class RoutingParameters
  attr_reader :destination, :dial_string_prefix, :plus_prefix, :national_dialing,
              :host, :username, :sip_profile, :address, :services_client

  DEFAULT_SIP_PROFILE = "nat_gateway".freeze

  def initialize(options)
    options.symbolize_keys!
    @address = options.fetch(:address)
    @destination = options.fetch(:destination)
    @dial_string_prefix = options.fetch(:dial_string_prefix)
    @plus_prefix = options.fetch(:plus_prefix)
    @national_dialing = options.fetch(:national_dialing)
    @host = options.fetch(:host)
    @username = options.fetch(:username)
    @sip_profile = options.fetch(:sip_profile, DEFAULT_SIP_PROFILE)
    @services_client = options.fetch(:services_client) { Services::Client.new }
  end

  def destination_address
    return address if address.present?

    result = formatted_destination
    result = use_client_gateway? ? client_gateway_destination_address : public_gateway_address(result)
    result.prepend(dial_string_prefix) if dial_string_prefix.present?
    result.prepend("+") if plus_prefix
    result
  end

  def format_number(value)
    result = value.gsub(/\D/, "")
    if Phony.plausible?(result)
      if national_dialing
        result = Phony.format(result, format: :national, spaces: "").gsub(/\D/, "")
      elsif plus_prefix
        result.prepend("+")
      end
    end

    result
  end

  def proxy_address
    return unless use_client_gateway?

    client_gateway_dial_string.proxy_address
  end

  private

  def use_client_gateway?
    username.present?
  end

  def formatted_destination
    format_number(destination).gsub(/\D/, "")
  end

  def client_gateway_destination_address
    client_gateway_dial_string.destination_address.dup
  end

  def client_gateway_dial_string
    @client_gateway_dial_string ||= services_client.build_client_gateway_dial_string(
      destination: formatted_destination,
      username:,
    )
  end

  def public_gateway_address(destination)
    "#{destination}@#{host}"
  end
end
