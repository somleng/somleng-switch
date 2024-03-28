class MediaStreamEventNotifier
  def notify(...)
    NotifyMediaStreamEventJob.perform_async(...)
  end
end
