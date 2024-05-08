require_relative "execute_twiml_verb"

class ExecuteConnect < ExecuteTwiMLVerb
  class EventHandler
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

  attr_reader :redis_connection, :event_handler, :call_update_event_handler

  def initialize(verb, **options)
    super
    @redis_connection = options.fetch(:redis_connection) { -> { AppSettings.redis } }
    @event_handler = options.fetch(:event_handler) { EventHandler.new }
    @call_update_event_handler = options.fetch(:call_update_event_handler) { CallUpdateEventHandler.new }
  end

  def call
    answer!

    url = verb.stream_noun.url
    custom_parameters = verb.stream_noun.parameters
    response = create_media_stream(url:, custom_parameters:, tracks: :inbound)
    stream_sid = response.id

    subscribe_to = [
      event_handler.channel_for(stream_sid),
      call_update_event_handler.channel_for(phone_call.id)
    ]

    redis_connection.call.with do |connection|
      connection.subscribe(*subscribe_to) do |on|
        on.subscribe do |channel|
          if event_handler.handle_events_for?(channel, stream_sid)
            start_stream!(url:, stream_sid:, custom_parameters:)
          end
        end

        on.message do |channel, message|
          if event_handler.handle_events_for?(channel, stream_sid)
            handle_stream_event(message) { |event| connection.unsubscribe if event.disconnect? }
          elsif call_update_event_handler.handle_events_for?(channel, phone_call.id)
            handle_call_update_event(message) { connection.unsubscribe(channel) }
          end
        end
      end
    end

    call_update_event_handler.perform_queued
  end

  private

  def handle_stream_event(message, &)
    event = event_handler.parse_event(message)
    event_handler.perform_now(event)
    yield(event)
  end

  def handle_call_update_event(message, &)
    event = call_update_event_handler.parse_event(message)
    call_update_event_handler.perform_later(event)
    yield(event)
    stop_stream!
  end

  def create_media_stream(**params)
    call_platform_client.create_media_stream(
      phone_call_id: call_properties.call_sid, **params
    )
  end

  def start_stream!(url:, stream_sid:, custom_parameters:)
    context.write_and_await_response(
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
    )
  end

  def stop_stream!
    context.write_and_await_response(
      Rayo::Command::TwilioStream::Stop.new(uuid: phone_call.id)
    )
  end
end
