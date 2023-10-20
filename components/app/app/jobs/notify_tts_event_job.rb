class NotifyTTSEventJob
  include SuckerPunch::Job

  def perform(client, data)
    client.notify_tts_event(data)
  end
end
