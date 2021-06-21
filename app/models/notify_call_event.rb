class NotifyCallEvent
  attr_reader :event, :client

  EVENT_TYPES = {
    Adhearsion::Event::Ringing => :ringing,
    Adhearsion::Event::Answered => :answered,
    Adhearsion::Event::End => :completed
  }.freeze

  def initialize(event, client: CallPlatform::Client.new)
    @event = event
    @client = client
  end

  def self.subscribe_events(call)
    EVENT_TYPES.each_key do |event_type|
      call.register_event_handler(event_type) { |event| new(event).call }
    end
  end

  def call
    client.notify_call_event(call_event_data)
  end

  private

  def call_event_data
    call_variables = {
      sip_term_status: event.headers["variable-sip_term_status"].presence,
      answer_epoch: event.headers["variable-answer_epoch"].presence
    }.compact

    {
      type: EVENT_TYPES.fetch(event.class),
      phone_call: event.headers.fetch("variable-uuid"),
      variables: call_variables
    }
  end
end
