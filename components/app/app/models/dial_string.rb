class DialString
  attr_reader :options, :fs_host, :fs_port

  def initialize(options)
    @options = options.symbolize_keys
    @fs_host = options.fetch(:fs_host) { AppSettings.fetch(:fs_host) }
    @fs_port = options.fetch(:fs_port) { AppSettings.fetch(:fs_port) }
  end

  def to_s
    "{proxy_leg=true}sofia/internal/#{destination_address};fs_path=#{fs_path}"
  end

  def format_number(...)
    routing_parameters.format_number(...)
  end

  def proxy_address
    return if routing_parameters.proxy_address.blank?

    ";fs_path=sip:#{routing_parameters.proxy_address}"
  end

  def external_profile
    routing_parameters.sip_profile
  end

  private

  def routing_parameters
    @routing_parameters ||= RoutingParameters.new(options.fetch(:routing_parameters))
  end

  def destination_address
    routing_parameters.destination_address
  end

  def fs_path
    "sip:#{fs_host}:#{fs_port}"
  end
end
