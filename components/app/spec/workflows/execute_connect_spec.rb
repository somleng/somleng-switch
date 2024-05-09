require "spec_helper"

RSpec.describe ExecuteConnect, type: :call_controller do
  it "creates a media stream" do
    verb = build_verb(
      url: "wss://example.com/audio",
      custom_parameters: {
        "foo" => "bar",
        "bar" => "baz"
      }
    )
    call_platform_client = stub_call_platform_client(stream_sid: "stream-sid")
    controller = build_controller(
      stub_voice_commands: :write_and_await_response,
      call: build_fake_call(id: "call-id")
    )

    ExecuteConnect.call(
      verb,
      redis_connection: -> { stub_fake_redis(poll_for_messages: false) },
      **build_workflow_options(
        context: controller,
        call_platform_client:,
        call_properties: { call_sid: "call-sid", account_sid: "account-sid" }
      )
    )

    expect(call_platform_client).to have_received(:create_media_stream).with(
      url: "wss://example.com/audio",
      phone_call_id: "call-sid",
      tracks: :inbound,
      custom_parameters: {
        "foo" => "bar",
        "bar" => "baz"
      }
    )
    expect(controller).to have_received(:write_and_await_response) do |command|
      expect(command).to have_attributes(
        uuid: "call-id",
        url: "wss://example.com/audio",
        metadata: {
          call_sid: "call-sid",
          account_sid: "account-sid",
          stream_sid: "stream-sid",
          custom_parameters: {
            "foo" => "bar",
            "bar" => "baz"
          }
        }
      )
    end
  end

  it "handles stream disconnects" do
    verb = build_verb
    call_platform_client = stub_call_platform_client(stream_sid: "stream-sid")
    event_handler, disconnect_event = stub_event_handler(ConnectEventHandler, disconnect: true)
    redis_connection = stub_fake_redis(
      channels: {
        event_handler.channel_for("stream-sid") => [ "message" ]
      }
    )

    ExecuteConnect.call(
      verb,
      redis_connection: -> { redis_connection },
      **build_workflow_options(call_platform_client:, event_handler:)
    )

    expect(event_handler.handled_events).to match_array([ disconnect_event ])
  end

  it "handles call updates" do
    verb = build_verb
    call_platform_client = stub_call_platform_client(stream_sid: "stream-sid")
    event_handler, disconnect_event = stub_event_handler(ConnectEventHandler, disconnect: true)
    call_update_event_handler, call_update_event = stub_event_handler(CallUpdateEventHandler)
    redis_connection = stub_fake_redis(
      channels: {
        call_update_event_handler.channel_for("call-id") => [ "message" ],
        event_handler.channel_for("stream-sid") => [ "message" ]
      }
    )
    controller = build_controller(
      stub_voice_commands: :write_and_await_response,
      call: build_fake_call(id: "call-id")
    )

    ExecuteConnect.call(
      verb,
      redis_connection: -> { redis_connection },
      **build_workflow_options(
        call_platform_client:,
        context: controller,
        event_handler:,
        call_update_event_handler:
      )
    )

    expect(event_handler.handled_events).to match_array([ disconnect_event ])
    expect(call_update_event_handler.handled_events).to match_array([ call_update_event ])
    expect(controller).to have_received(:write_and_await_response).with(an_instance_of(Rayo::Command::TwilioStream::Stop))
  end

  def stub_fake_redis(channels: {}, poll_for_messages: true)
    fake_redis = FakeRedis.new(subscription_options: { poll_for_messages: })
    channels.each do |channel, messages|
      messages.each do |message|
        fake_redis.publish_later(channel, message)
      end
    end
    fake_redis
  end

  def stub_call_platform_client(stream_sid: "stream-sid")
    instance_double(
      CallPlatform::Client,
      create_media_stream: CallPlatform::Client::AudioStreamResponse.new(id: stream_sid)
    )
  end

  def build_workflow_options(**options)
    call_properties = build_call_properties(**options.delete(:call_properties) || {})
    context = options.fetch(:context) { build_controller(stub_voice_commands: :write_and_await_response) }

    {
      context:,
      call_properties:,
      phone_call: context.call,
      call_platform_client: context.call_platform_client,
      **options
    }
  end

  def build_verb(**options)
    url = options.delete(:url) || "ws://example.com/audio"
    custom_parameters = options.delete(:custom_parameters) || {}

    TwiML::ConnectVerb.new(
      name: "Connect",
      stream_noun: TwiML::ConnectVerb::StreamNoun.new(
        url:,
        parameters: custom_parameters
      ),
      **options
    )
  end

  def stub_event_handler(type, **options)
    event_handler = build_fake_event_handler(type)
    event = event_handler.fake_event(**options)
    allow(event_handler).to receive(:parse_event).and_return(event)

    [ event_handler, event ]
  end

  def build_fake_event_handler(type)
    event_handler = Class.new(type) do
      attr_reader :handled_events

      def initialize
        super()
        @handled_events = []
      end

      def perform_now(event)
        handled_events << event
      end
    end

    event_handler.new
  end
end
