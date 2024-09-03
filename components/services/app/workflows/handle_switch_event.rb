class HandleSwitchEvent < ApplicationWorkflow
  attr_reader :event, :regions

  def initialize(event:, regions:)
    @event = event
    @regions = regions
  end

  def call
    if event.task_running? && event.eni_attached?
      load_balancer_manager.create_targets(group_id: load_balancer_group)
    elsif event.task_stopped? && event.eni_deleted?
      load_balancer_manager.delete_targets
    end
  end

  private

  def load_balancer_group
    regions.find_by!(identifier: event.region).group_id
  end

  def load_balancer_manager
    @load_balancer_manager ||= ManageLoadBalancerTargets.new(ip_address: event.private_ip)
  end
end
