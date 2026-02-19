class DialString
  attr_reader :options, :fs_path

  def initialize(options)
    @options = options.symbolize_keys
    @fs_path = options.fetch(:fs_path) { AppSettings.fetch(:fs_path) }
  end

  def to_s
    "{proxy_leg=true}sofia/#{external_profile}/#{destination_address};fs_path=#{fs_path}"
  end

  def format_number(...)
    routing_parameters.format_number(...)
  end

  def proxy_address
    return if routing_parameters.proxy_address.blank?

    ";fs_path=#{routing_parameters.proxy_address}"
  end

  private

  def routing_parameters
    @routing_parameters ||= RoutingParameters.new(options.fetch(:routing_parameters))
  end

  def destination_address
    routing_parameters.destination_address
  end

  def external_profile
    routing_parameters.sip_profile
  end
end
