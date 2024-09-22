
require "zlib"
require "base64"
require "stringio"

class CloudWatchLogEventParser
  LogEvent = Struct.new(
    :timestamp,
    :message,
  )

  Event = Struct.new(
    :event_type,
    :log_group,
    :log_events,
    keyword_init: true
  )

  attr_reader :event

  def initialize(event)
    @event = event
  end

  def parse_event
    Event.new(
      event_type: :cloudwatch_log_event,
      log_group:,
      log_events:
    )
  end

  private

  def raw_data
    event.dig("awslogs", "data")
  end

  def data_message
    @data_message ||= JSON.parse(Zlib::GzipReader.new(StringIO.new(Base64.decode64(raw_data))).read)
  end

  def log_group
    data_message.fetch("logGroup")
  end

  def log_events
    data_message.fetch("logEvents").map do |log_event_data|
      LogEvent.new(
        timestamp: Time.at(log_event_data.fetch("timestamp") / 1000),
        message: log_event_data.fetch("message")
      )
    end
  end
end
