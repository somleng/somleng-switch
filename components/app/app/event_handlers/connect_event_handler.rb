class ConnectEventHandler
  CHANNEL_PREFIX = "mod_twilio_stream".freeze

  class Event
    DISCONNECT_EVENTS = [ "connect_failed", "disconnect" ].freeze

    attr_reader :type, :stream_sid

    def initialize(**params)
      @type = params.fetch(:type)
      @disconnect = params.fetch(:disconnect)
      @stream_sid = params.fetch(:stream_sid)
    end

    def disconnect?
      @disconnect
    end

    def self.parse(payload)
      message = JSON.parse(payload)

      new(
        type: ActiveSupport::StringInquirer.new(message.fetch("event")),
        stream_sid: message.fetch("streamSid"),
        disconnect: message.fetch("event").in?(DISCONNECT_EVENTS)
      )
    end
  end

  attr_reader :call_platform_client, :event_notifier

  def initialize(call_platform_client: CallPlatform::Client.new, event_notifier: MediaStreamEventNotifier.new)
    @call_platform_client = call_platform_client
    @event_notifier = event_notifier
  end

  def perform_now(event)
    event_notifier.notify(
      call_platform_client,
      media_stream_id: event.stream_sid, event: { type: event.type }
    )
  end

  def parse_event(message)
    Event.parse(message)
  end

  def channel_for(stream_sid)
    "#{CHANNEL_PREFIX}:#{stream_sid}"
  end

  def handle_events_for?(channel, stream_sid)
    channel == channel_for(stream_sid)
  end

  def fake_event(**params)
    Event.new(
      type: "connect",
      disconnect: false,
      stream_sid: SecureRandom.uuid,
      **params
    )
  end
end
