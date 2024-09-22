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
    elsif service_action?
               ServiceActionParser
    elsif cloudwatch_log_event?
               CloudWatchLogEventParser
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

  def service_action?
    event.key?("serviceAction")
  end

  def cloudwatch_log_event?
    event.keys.size == 1 && event.key?("awslogs")
  end
end
