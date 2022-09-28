class LoadBalancerTarget
  attr_reader :ip_address, :port, :resources_identifier

  def initialize(ip_address:, port:, resources_identifier:)
    @ip_address = ip_address
    @port = port
    @resources_identifier = resources_identifier
  end

  def dst_uri
    "sip:#{ip_address}:#{port}"
  end

  def resources
    "#{resources_identifier}=#{event_socket_url}"
  end

  private

  def event_socket_url
    "fs://:#{fs_event_socket_password}@#{ip_address}:#{fs_event_socket_port}"
  end

  def fs_event_socket_password
    ENV.fetch("FS_EVENT_SOCKET_PASSWORD")
  end

  def fs_event_socket_port
    ENV.fetch("FS_EVENT_SOCKET_PORT", "8021")
  end
end
