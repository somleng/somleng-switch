class OpenSIPSLogEventParser
  attr_reader :event

  Event = Struct.new(:level, :message, keyword_init: true)

  def initialize(event)
    @event = event
  end

  def parse_event
    event.log_events.map do |log_event|
      log_data = JSON.parse(log_event.message)

      Event.new(level: log_data.fetch("level"), message: log_data.fetch("message"))
    end
  end
end
