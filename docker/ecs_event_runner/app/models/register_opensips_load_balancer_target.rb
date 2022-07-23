class RegisterOpenSIPSLoadBalancerTarget < ApplicationWorkflow
  attr_reader :load_balancer_target

  def initialize(target_ip:)
    @load_balancer_target = OpenSIPSLoadBalancerTarget.new(target_ip:)
  end

  def call
    create_load_balancer_target unless load_balancer_target_exists?
  end

  private

  def load_balancer_target_exists?
    database_connection.any_records?(
      "SELECT 1 FROM load_balancer WHERE dst_uri = '#{load_balancer_target.dst_uri}';"
    )
  end

  def create_load_balancer_target
    database_connection.exec(
      "INSERT INTO load_balancer (group_id, dst_uri, resources, probe_mode) VALUES (#{load_balancer_target.group_id}, '#{load_balancer_target.dst_uri}', '#{load_balancer_target.resources}', #{load_balancer_target.probe_mode});"
    )
  end

  def database_connection
    @database_connection ||= DatabaseConnection.new(db_name: ENV.fetch("OPENSIPS_DB_NAME"))
  end
end
