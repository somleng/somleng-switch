class NotifyCallEventJob
  include SuckerPunch::Job

  def perform(client, data)
    client.notify_call_event(data)
  end
end
