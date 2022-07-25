class OpenSIPSLoadBalancerTarget
  attr_reader :target_ip

  def initialize(target_ip:)
    @target_ip = target_ip
  end

  def dst_uri
    "sip:#{target_ip}:5060"
  end

  def resources
    "#{resource_type}=#{event_socket_url}"
  end

  def group_id
    ENV.fetch("OPENSIPS_LOAD_BALANCER_GROUP_ID", 1)
  end

  def probe_mode
    ENV.fetch("OPENSIPS_LOAD_BALANCER_PROBE_MODE", 2)
  end

  private

  def event_socket_url
    "fs://:#{fs_event_socket_password}@#{target_ip}:#{fs_event_socket_port}"
  end

  def fs_event_socket_password
    ENV.fetch("FS_EVENT_SOCKET_PASSWORD")
  end

  def fs_event_socket_port
    ENV.fetch("FS_EVENT_SOCKET_PORT", "8021")
  end

  def resource_type
    ENV.fetch("OPENSIPS_LOAD_BALANCER_RESOURCE_TYPE", "pstn")
  end
end
