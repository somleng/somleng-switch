class ServiceActionParser
  attr_reader :event

  Event = Struct.new(
    :event_type,
    :service_action,
    :parameters,
    keyword_init: true
  )

  def initialize(event)
    @event = event
  end

  def parse_event
    Event.new(
      event_type: :service_action,
      service_action: Object.const_get(event.fetch("serviceAction")),
      parameters: JSON.parse(event.fetch("parameters", "{}")).transform_keys(&:to_sym)
    )
  end
end
