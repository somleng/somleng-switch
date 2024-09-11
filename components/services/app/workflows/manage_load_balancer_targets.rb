class ManageLoadBalancerTargets < ApplicationWorkflow
  attr_reader :ip_address

  def initialize(ip_address:)
    @ip_address = ip_address
  end

  def create_targets(**)
    gateway_databases.each do |database_connection|
      database_connection.transaction do
        load_balancer_targets.each do |load_balancer_target|
          create_opensips_load_balancer_target!(load_balancer_target:, database_connection:, **)
        end
      end
    end
  end

  def delete_targets
    gateway_databases.each do |database_connection|
      OpenSIPSLoadBalancerTarget.where(
        dst_uri: load_balancer_targets.map(&:dst_uri),
        database_connection:
      ).delete
    end
  end

  private

  def create_opensips_load_balancer_target!(load_balancer_target:, database_connection:, **attributes)
    return if OpenSIPSLoadBalancerTarget.exists?(dst_uri: load_balancer_target.dst_uri, database_connection:)

    OpenSIPSLoadBalancerTarget.new(
      dst_uri: load_balancer_target.dst_uri,
      resources: load_balancer_target.resources,
      group_id: 1,
      probe_mode: 2,
      database_connection:,
      **attributes
    ).save!
  end

  def gateway_databases
    @gateway_databases ||= DatabaseConnections.gateways
  end

  def load_balancer_targets
    @load_balancer_targets ||= [
      build_load_balancer_target(port: fs_sip_port, resources_identifier: "gw"),
      build_load_balancer_target(port: fs_sip_alternative_port, resources_identifier: "gwalt")
    ]
  end

  def build_load_balancer_target(port:, resources_identifier:)
    LoadBalancerTarget.new(ip_address:, port:, resources_identifier:)
  end

  def fs_sip_port
    ENV.fetch("FS_SIP_PORT", "5060")
  end

  def fs_sip_alternative_port
    ENV.fetch("FS_SIP_ALTERNATIVE_PORT", "5080")
  end
end
