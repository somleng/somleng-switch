class HandleSwitchEvent < ApplicationWorkflow
  attr_reader :event

  def initialize(event:)
    @event = event
  end

  def call
    if event.task_running? && event.eni_attached?
      load_balancer_manager.create_targets
    elsif event.task_stopped? && event.eni_deleted?
      load_balancer_manager.delete_targets
    end
  end

  private

  def load_balancer_manager
    @load_balancer_manager ||= ManageLoadBalancerTargets.new(ip_address: event.private_ip)
  end
end
