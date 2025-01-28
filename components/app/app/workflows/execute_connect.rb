require_relative "execute_twiml_verb"

class ExecuteConnect < ExecuteTwiMLVerb
  attr_reader :redis_connection, :event_handler, :call_update_event_handler

  def initialize(verb, **options)
    super
    @redis_connection = options.fetch(:redis_connection) { -> { AppSettings.redis } }
    @event_handler = options.fetch(:event_handler) { ConnectEventHandler.new(call_platform_client:) }
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
            handle_stream_event(message) do |event|
              next unless event.disconnect?

              connection.unsubscribe
              DisconnectTwilioStream.call(context)
            end
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
    StartTwilioStream.call(context, url:, stream_sid:, call_properties:, custom_parameters:)
  end

  def stop_stream!
    StopTwilioStream.call(context)
  end
end
