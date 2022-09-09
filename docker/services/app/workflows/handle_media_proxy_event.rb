class HandleMediaProxyEvent < ApplicationWorkflow
  attr_reader :event

  def initialize(event:)
    @event = event
  end

  def call
    if event.task_running?
      opensips_rtpengine_target.save!
    elsif event.task_stopped?
      opensips_rtpengine_target.delete!
    end
  end

  private

  def opensips_rtpengine_target
    OpenSIPSRTPEngineTarget.new(
      target_ip: event.private_ip, database_connection: DatabaseConnections.find(:client_gateway)
    )
  end
end
