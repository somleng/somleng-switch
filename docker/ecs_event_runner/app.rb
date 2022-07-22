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
      HandleSwitchEvent.call(event:) if event.group == switch_group
    end

    private

    def switch_group
      ENV.fetch("SWITCH_GROUP")
    end
  end
end
