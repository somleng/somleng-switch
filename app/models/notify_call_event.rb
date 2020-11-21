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

  def call
    client.notify_call_event(call_event_data)
  end

  private

  def call_event_data
    {
      type: EVENT_TYPES.fetch(event.class),
      phone_call: event.headers.fetch("variable-uuid"),
      variables: {
        sip_term_status: event.headers["variable-sip_term_status"].presence,
        answer_epoch: event.headers["variable-answer_epoch"].presence
      }.compact
    }
  end
end
