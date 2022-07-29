class OpenSIPSLoadBalancerTarget < ApplicationWorkflow
  attr_reader :target_ip

  def initialize(target_ip:)
    @target_ip = target_ip
  end

  def register!
    create_load_balancer_target unless load_balancer_target_exists?
  end

  def deregister!
    delete_load_balancer_target
  end

  private

  def load_balancer_target_exists?
    database_connection.any_records?(
      "SELECT 1 FROM load_balancer WHERE dst_uri = '#{dst_uri}';"
    )
  end

  def create_load_balancer_target
    database_connection.exec(<<-SQL)
      INSERT INTO load_balancer (group_id, dst_uri, resources, probe_mode)
      VALUES (1, '#{dst_uri}', '#{resources}', 2),
             (1, '#{alternative_dst_uri}', '#{resources}', 2);
    SQL
  end

  def delete_load_balancer_target
    database_connection.exec(<<-SQL)
      DELETE FROM load_balancer
      WHERE dst_uri='#{dst_uri}' OR dst_uri='#{alternative_dst_uri}';
    SQL
  end

  def database_connection
    @database_connection ||= DatabaseConnection.new(db_name: ENV.fetch("OPENSIPS_DB_NAME"))
  end

  def dst_uri
    "sip:#{target_ip}:#{fs_sip_port}"
  end

  def alternative_dst_uri
    "sip:#{target_ip}:#{fs_sip_alternative_port}"
  end

  def resources
    "pstn=#{event_socket_url}"
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

  def fs_sip_port
    ENV.fetch("FS_SIP_PORT", "5060")
  end

  def fs_sip_alternative_port
    ENV.fetch("FS_SIP_ALTERNATIVE_PORT", "5080")
  end
end
