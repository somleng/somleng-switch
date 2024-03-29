class NotifyMediaStreamEventJob
  include SuckerPunch::Job

  def perform(client, data)
    client.notify_media_stream_event(data)
  end
end
