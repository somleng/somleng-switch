class SQSMessageEventParser
  Event = Struct.new(
    :records,
    :event_type,
    keyword_init: true
  )

  Record = Struct.new(
    :body,
    :job_class,
    :job_args,
    keyword_init: true
  )

  attr_reader :event

  def initialize(event)
    @event = event
  end

  def parse_event
    Event.new(event_type: :sqs_message, records:)
  end

  private

  def records
    event.fetch("Records").each_with_object([]) do |record, result|
      body = JSON.parse(record.fetch("body"))

      result << Record.new(
        job_class: body.fetch("job_class").constantize,
        job_args: body.fetch("job_args", [])
      )
    end
  end
end
