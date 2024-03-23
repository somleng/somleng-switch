require_relative "execute_twiml_verb"

class ExecuteConnect < ExecuteTwiMLVerb
  class ExecuteCommand < ExecuteTwiMLVerb
    CHANNEL_PREFIX = "mod_twilio_stream".freeze

    Event = Struct.new(:type, :disconnect?, keyword_init: true) do
      DISCONNECT_EVENTS = [ "connect_failed", "disconnect" ].freeze

      def self.parse(payload)
        message = JSON.parse(payload)

        new(
          type: ActiveSupport::StringInquirer.new(message.fetch("event")),
          disconnect?: message.fetch("event").in?(DISCONNECT_EVENTS)
        )
      end
    end

    def execute(stream_sid:, **)
      subscribe_to_stream_events("#{CHANNEL_PREFIX}:#{stream_sid}") do
        context.write_and_await_response(build_command(stream_sid:, **))
      end
    end

    private

    def build_command(url:, stream_sid:, custom_parameters:)
      Rayo::Command::TwilioStream::Start.new(
        uuid: phone_call.id,
        url:,
        metadata: {
          call_sid: call_properties.call_sid,
          account_sid: call_properties.account_sid,
          stream_sid:,
          custom_parameters:
        }.to_json
      )
    end

    def subscribe_to_stream_events(channel_name, &)
      AppSettings.redis.with do |redis|
        redis.subscribe(channel_name) do |on|
          on.subscribe(&)
          on.message do |_channel, message|
            event = Event.parse(message)
            redis.unsubscribe(channel_name) if event.disconnect?
          end
        end
      end
    end
  end

  attr_reader :execute_command

  def initialize(verb, execute_command: nil, **)
    super
    @execute_command = execute_command || ExecuteCommand.new(verb, **)
  end

  def call
    answer!

    url = verb.stream_noun.url
    custom_parameters = verb.stream_noun.parameters
    response = create_audio_stream(url:, custom_parameters:)

    execute_command.execute(url:, stream_sid: response.id, custom_parameters:)
  end

  private

  def create_audio_stream(**params)
    call_platform_client.create_audio_stream(phone_call_id: call_properties.call_sid, **params)
  end
end
