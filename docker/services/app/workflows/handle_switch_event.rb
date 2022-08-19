class HandleSwitchEvent < ApplicationWorkflow
  attr_reader :event

  def initialize(event:)
    @event = event
  end

  def call
    if event.task_running? && event.eni_attached?
      opensips_load_balancer_target.save!
    elsif event.task_stopped? && event.eni_deleted?
      opensips_load_balancer_target.delete!
    end
  end

  private

  def opensips_load_balancer_target
    OpenSIPSLoadBalancerTarget.new(target_ip: event.eni_private_ip)
  end
end
