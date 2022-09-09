class HandleSwitchEvent < ApplicationWorkflow
  attr_reader :event

  def initialize(event:)
    @event = event
  end

  def call
    if event.task_running? && event.eni_attached?
      create_opensips_load_balancer_targets
    elsif event.task_stopped? && event.eni_deleted?
      delete_opensips_load_balancer_targets
    end
  end

  private

  def create_opensips_load_balancer_targets
    gateway_databases.each do |database_connection|
      opensips_load_balancer_target(database_connection).save!
    end
  end

  def delete_opensips_load_balancer_targets
    gateway_databases.each do |database_connection|
      opensips_load_balancer_target(database_connection).delete!
    end
  end

  def gateway_databases
    @gateway_databases ||= DatabaseConnections.gateways
  end

  def opensips_load_balancer_target(database_connection)
    OpenSIPSLoadBalancerTarget.new(target_ip: event.eni_private_ip, database_connection:)
  end
end
