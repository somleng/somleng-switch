class HandleSwitchEvent < ApplicationWorkflow
  attr_reader :event

  def initialize(event:)
    @event = event
  end

  def call
    if event.task_running?
      handle_switch_running_event
    elsif event.task_stopped?
      handle_switch_stopped_event
    end
  end

  private

  def handle_switch_running_event
    RegisterOpenSIPSLoadBalancerTarget.call(target_ip: event.eni_private_ip)
  end

  def handle_switch_stopped_event
    DeregisterOpenSIPSLoadBalancerTarget.call(target_ip: event.eni_private_ip)
  end
end
