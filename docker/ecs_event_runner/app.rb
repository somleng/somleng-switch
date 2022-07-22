Dir["#{File.dirname(__FILE__)}/app/**/*.rb"].sort.each { |f| require f }

module App
  class Handler
    attr_reader :event, :context

    def self.process(event:, context:)
      new(event:, context:).process
    end

    def initialize(event:, context:)
      @event = ECSEventParser.new(event).parse_event
      @context = context
    end

    def process
      HandleSwitchEvent.call(event:) if event.task_family == switch_task_family
    end

    private

    def switch_task_family
      ENV.fetch("SWITCH_TASK_FAMILY")
    end
  end
end
