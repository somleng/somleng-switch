require_relative "execute_twiml_verb"

class ExecuteConnect < ExecuteTwiMLVerb
  CHANNEL_PREFIX = "mod_twilio_stream".freeze
  DISCONNECT_EVENTS = [ "connect_failed", "disconnect" ].freeze

  Event = Struct.new(:type, :disconnect?, :stream_sid, keyword_init: true) do
    def self.parse(payload)
      message = JSON.parse(payload)

      new(
        type: ActiveSupport::StringInquirer.new(message.fetch("event")),
        stream_sid: message.fetch("streamSid"),
        disconnect?: message.fetch("event").in?(DISCONNECT_EVENTS)
      )
    end
  end

  class EventHandler
    attr_reader :event, :call_platform_client, :event_notifier

    def initialize(event, call_platform_client:, event_notifier: MediaStreamEventNotifier.new)
      @event = event
      @call_platform_client = call_platform_client
      @event_notifier = event_notifier
    end

    def call
      event_notifier.notify(
        call_platform_client,
        media_stream_id: event.stream_sid, event: { type: event.type }
      )
    end
  end

  attr_reader :redis_connection, :event_handler

  def initialize(verb, **options)
    super
    @redis_connection = options.fetch(:redis_connection) { -> { AppSettings.redis } }
    @event_handler = options.fetch(:event_handler) { ->(event) { EventHandler.new(event, call_platform_client:).call } }
  end

  def call
    answer!

    url = verb.stream_noun.url
    custom_parameters = verb.stream_noun.parameters
    response = create_media_stream(url:, custom_parameters:)

    execute_command(url:, custom_parameters:, stream_sid: response.id)
  end

  private

  def create_media_stream(**params)
    call_platform_client.create_media_stream(phone_call_id: call_properties.call_sid, **params)
  end

  def execute_command(stream_sid:, **)
    subscribe_to_stream_events("#{CHANNEL_PREFIX}:#{stream_sid}") do
      context.write_and_await_response(build_command(stream_sid:, **))
    end
  end

  def build_command(url:, stream_sid:, custom_parameters:)
    Rayo::Command::TwilioStream::Start.new(
      uuid: phone_call.id,
      url:,
      metadata: {
        call_sid: call_properties.call_sid,
        account_sid: call_properties.account_sid,
        stream_sid:,
        custom_parameters:
      }
    )
  end

  def subscribe_to_stream_events(channel_name, &)
    redis_connection.call.with do |redis|
      redis.subscribe(channel_name) do |on|
        on.subscribe(&)
        on.message do |_channel, message|
          event = Event.parse(message)
          event_handler.call(event)
          redis.unsubscribe(channel_name) if event.disconnect?
        end
      end
    end
  end
end
