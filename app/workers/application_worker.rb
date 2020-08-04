class ApplicationWorker
  include Shoryuken::Worker

  shoryuken_options(
    auto_delete: true,
    auto_visibility_timeout: true,
    retry_intervals: ->(attempts) { (12.hours.seconds**(attempts / 10.0)).to_i }
  )
end
