class SQSMessageEventParser
  Event = Struct.new(
    :records,
    :event_type,
    keyword_init: true
  )

  Record = Struct.new(
    :body,
    :attributes,
    :event_source_arn,
    keyword_init: true
  )

  attr_reader :event

  def initialize(event)
    @event = event
  end

  def parse_event
    Event.new(
      event_type: :sqs_message,
      records:
    )
  end

  private

  def records
    event.fetch("Records").each_with_object([]) do |record, result|
      result << Record.new(
        body: record.fetch("body"),
        attributes: record.fetch("attributes"),
        event_source_arn: record.fetch("eventSourceARN")
      )
    end
  end
end
