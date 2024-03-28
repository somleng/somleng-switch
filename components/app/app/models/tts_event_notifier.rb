class TTSEventNotifier
  def notify(...)
    NotifyTTSEventJob.perform_async(...)
  end
end
