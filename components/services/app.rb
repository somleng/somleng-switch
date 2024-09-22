require "logger"

require_relative "config/application"

module App
  class Handler
    attr_reader :event, :context

    def self.process(event:, context:)
      logger = Logger.new($stdout)
      logger.info("## Processing Event")
      logger.info(event)

      new(event:, context:).process
    rescue Exception => e
      Sentry.capture_exception(e)
      raise(e)
    end

    def initialize(event:, context:)
      @event = EventParser.new(event).parse_event
      @context = context
    end

    def process
      case event.event_type
      when :ecs
        handle_ecs_event(event)
      when :sqs_message
        HandleSQSMessageEvent.call(event:)
      when :service_action
        event.service_action.call(**event.parameters)
      when :cloudwatch_log_event
        p "handling event: #{event}"
        HandleLogEvents.call(event:)
      end
    end

    private

    def handle_ecs_event(event)
      case event.group
      when ENV.fetch("SWITCH_GROUP")
        HandleSwitchEvent.call(event:, regions: SomlengRegion::Region)
      when ENV.fetch("MEDIA_PROXY_GROUP")
        HandleMediaProxyEvent.call(event:)
      when ENV.fetch("CLIENT_GATEWAY_GROUP")
        HandleClientGatewayEvent.call(event:)
      end
    end
  end
end
