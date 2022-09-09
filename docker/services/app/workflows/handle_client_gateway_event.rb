class HandleClientGatewayEvent < ApplicationWorkflow
  attr_reader :event

  def initialize(event:)
    @event = event
  end

  def call
    if event.task_running?
      build_domain(ip: event.private_ip).save!
      build_domain(ip: event.public_ip).save!
    elsif event.task_stopped?
      build_domain(ip: event.private_ip).delete!
      build_domain(ip: event.public_ip).delete!
    end
  end

  private

  def build_domain(ip:)
    OpenSIPSDomain.new(
      ip:, database_connection: DatabaseConnections.find(:client_gateway)
    )
  end
end
