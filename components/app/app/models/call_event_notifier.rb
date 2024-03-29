class CallEventNotifier
  def notify(...)
    NotifyCallEventJob.perform_async(...)
  end
end
