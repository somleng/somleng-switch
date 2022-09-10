class HandleClientGatewayEvent < ApplicationWorkflow
  attr_reader :event

  def initialize(event:)
    @event = event
  end

  def call
    domains = [event.private_ip, event.public_ip]
    if event.task_running?
      database_connection.transaction do
        domains.each { |domain| create_domain!(domain:) }
      end
    elsif event.task_stopped?
      database_connection.transaction do
        domains.each { |domain| OpenSIPSDomain.where(domain:, database_connection:).delete }
      end
    end
  end

  private

  def create_domain!(domain:)
    return if OpenSIPSDomain.exists?(domain:, database_connection:)

    OpenSIPSDomain.new(domain:, last_modified: Time.now, database_connection:).save!
  end

  def database_connection
    @database_connection ||= DatabaseConnections.find(:client_gateway)
  end
end
