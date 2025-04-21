class HandleMediaProxyEvent < ApplicationWorkflow
  attr_reader :event

  def initialize(event:)
    super()
    @event = event
  end

  def call
    if event.task_running?
      create_media_proxy_target!
    elsif event.task_stopped?
      OpenSIPSRTPEngineTarget.where(socket:, database_connection:).delete
    end
  end

  private

  def create_media_proxy_target!
    return if OpenSIPSRTPEngineTarget.exists?(socket:, database_connection:)

    OpenSIPSRTPEngineTarget.new(socket:, set_id: 0, database_connection:).save!
  end

  def socket
    "udp:#{event.private_ip}:#{socket_port}"
  end

  def socket_port
    ENV.fetch("MEDIA_PROXY_NG_PORT")
  end

  def database_connection
    @database_connection ||= DatabaseConnections.find(:client_gateway)
  end
end
