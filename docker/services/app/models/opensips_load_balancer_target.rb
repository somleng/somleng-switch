class OpenSIPSLoadBalancerTarget < ApplicationRecord
  attr_reader :target_ip

  def initialize(target_ip:, **options)
    super(**options)
    @target_ip = target_ip
  end

  def save!
    create_load_balancer_target unless load_balancer_target_exists?
  end

  def delete!
    delete_load_balancer_target
  end

  private

  def load_balancer_target_exists?
    load_balancer.where(dst_uri:).count.positive?
  end

  def create_load_balancer_target
    database_connection.transaction do
      load_balancer.insert(group_id: 1, dst_uri:, resources:, probe_mode: 2)
      load_balancer.insert(group_id: 1, dst_uri: alternative_dst_uri, resources: alternative_resources, probe_mode: 2)
    end
  end

  def delete_load_balancer_target
    load_balancer.where(dst_uri: [dst_uri, alternative_dst_uri]).delete
  end

  def load_balancer
    @load_balancer ||= database_connection.table(:load_balancer)
  end

  def dst_uri
    "sip:#{target_ip}:#{fs_sip_port}"
  end

  def alternative_dst_uri
    "sip:#{target_ip}:#{fs_sip_alternative_port}"
  end

  def resources
    "gw=#{event_socket_url}"
  end

  def alternative_resources
    "gwalt=#{event_socket_url}"
  end

  def event_socket_url
    "fs://:#{fs_event_socket_password}@#{target_ip}:#{fs_event_socket_port}"
  end

  def fs_event_socket_password
    ENV.fetch("FS_EVENT_SOCKET_PASSWORD")
  end

  def fs_event_socket_port
    ENV.fetch("FS_EVENT_SOCKET_PORT", "8021")
  end

  def fs_sip_port
    ENV.fetch("FS_SIP_PORT", "5060")
  end

  def fs_sip_alternative_port
    ENV.fetch("FS_SIP_ALTERNATIVE_PORT", "5080")
  end
end
