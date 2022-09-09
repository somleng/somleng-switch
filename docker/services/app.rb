require "logger"

Dir["#{File.dirname(__FILE__)}/app/**/*.rb"].sort.each { |f| require f }

module App
  class Handler
    attr_reader :event, :context

    def self.process(event:, context:)
      logger = Logger.new($stdout)
      logger.info("## Processing Event")
      logger.info(event)

      new(event:, context:).process
    end

    def initialize(event:, context:)
      @event = EventParser.new(event).parse_event
      @context = context
    end

    def process
      DecryptEnvironmentVariables.call
      case event.event_type
      when :ecs
        handle_ecs_event(event)
      when :sqs_message
        HandleSQSMessageEvent.call(event:)
      end
    end

    private

    def handle_ecs_event(event)
      case event.group
      when ENV.fetch("SWITCH_GROUP")
        HandleSwitchEvent.call(event:)
      when ENV.fetch("MEDIA_PROXY_GROUP")
        HandleMediaProxyEvent.call(event:)
      when ENV.fetch("CLIENT_GATEWAY_GROUP")
        HandleClientGatewayEvent.call(event:)
      end
    end
  end
end
