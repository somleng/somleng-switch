class EventParser
  attr_reader :event

  def initialize(event)
    @event = event
  end

  def parse_event
    parser = if ecs_event?
               ECSEventParser
             elsif sqs_message_event?
               SQSMessageEventParser
             end

    parser.new(event).parse_event
  end

  private

  def sqs_message_event?
    event.key?("Records")
  end

  def ecs_event?
    event["detail-type"] == "ECS Task State Change"
  end
end
