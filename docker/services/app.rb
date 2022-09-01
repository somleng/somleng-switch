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
      when switch_group
        HandleSwitchEvent.call(event:)
      when sip_proxy_group || registrar_group
        HandleSIPProxyEvent.call(event:)
      end
    end

    def switch_group
      ENV.fetch("SWITCH_GROUP")
    end

    def sip_proxy_group
      ENV.fetch("SIP_PROXY_GROUP")
    end

    def registrar_group
      ENV.fetch("REGISTRAR_GROUP")
    end
  end
end
