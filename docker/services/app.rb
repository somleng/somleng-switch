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
        HandleSwitchEvent.call(event:) if event.group == switch_group
      when :sqs_message
        HandleSQSMessageEvent.call(event:)
      end
    end

    private

    def switch_group
      ENV.fetch("SWITCH_GROUP")
    end
  end
end
