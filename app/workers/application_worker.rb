class ApplicationWorker
  include Shoryuken::Worker

  shoryuken_options(
    auto_delete: true,
    auto_visibility_timeout: true,
    queue: ENV.fetch("AWS_SQS_DEFAULT_QUEUE_NAME", "default"),
    retry_intervals: ->(attempts) { (12.hours.seconds**(attempts / 10.0)).to_i }
  )
end
