class HandleClientGatewayEvent < ApplicationWorkflow
  attr_reader :event

  def initialize(event:)
    @event = event
  end

  def call
    if event.task_running?
      domain_manager.create_domains
    elsif event.task_stopped?
      domain_manager.delete_domains
    end
  end

  private

  def domain_manager
    @domain_manager ||= ManageDomains.new(domains: [event.private_ip, event.public_ip])
  end
end
