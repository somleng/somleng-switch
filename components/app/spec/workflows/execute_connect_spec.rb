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
      redis_connection: -> { stub_fake_redis },
      **build_workflow_options(
        context: controller,
        call_platform_client:,
        call_properties: { call_sid: "call-sid", account_sid: "account-sid" }
      )
    )

    expect(call_platform_client).to have_received(:create_media_stream).with(
      url: "wss://example.com/audio",
      phone_call_id: "call-sid",
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
    redis_connection = stub_fake_redis(has_messages_on_channel: "mod_twilio_stream:stream-sid")
    handled_events = []
    event_handler = ->(event) { handled_events << event }
    disconnect_event = ExecuteConnect::Event.new(disconnect?: true)
    allow(ExecuteConnect::Event).to receive(:parse).and_return(disconnect_event)

    ExecuteConnect.call(
      verb,
      redis_connection: -> { redis_connection },
      **build_workflow_options(call_platform_client:, event_handler:)
    )

    expect(redis_connection).to have_received(:unsubscribe).with("mod_twilio_stream:stream-sid")
    expect(handled_events).to match_array([ disconnect_event ])
  end


  describe ExecuteConnect::Event do
    it "parses events" do
      event_payload = { event: "connect_failed", streamSid: "stream-sid" }.to_json

      event = ExecuteConnect::Event.parse(event_payload)

      expect(event).to have_attributes(
        type: "connect_failed",
        disconnect?: true,
        stream_sid: "stream-sid"
      )
    end
  end

  describe ExecuteConnect::EventHandler do
    it "handles events" do
      call_platform_client = stub_call_platform_client
      event = ExecuteConnect::Event.new(type: "connect_failed", stream_sid: "stream-sid")
      event_handler = ExecuteConnect::EventHandler.new(event, call_platform_client:)

      event_handler.call

      expect(call_platform_client).to have_received(
        :notify_media_stream_event
      ).with(media_stream_id: "stream-sid", event: { type: "connect_failed" })
    end
  end

  def stub_fake_redis(has_messages_on_channel: nil, messages: [])
    if has_messages_on_channel.present?
      fake_redis = FakeRedis.new
      if messages.any?
        messages.each { |message| fake_redis.publish_later(has_messages_on_channel, message) }
      else
        fake_redis.publish_later(has_messages_on_channel, "dummy-message")
      end
    else
      fake_subscription = FakeRedis::DefaultSubscription.new
      allow(fake_subscription).to receive(:message)
      fake_redis = FakeRedis.new(default_subscription: fake_subscription)
    end
    allow(fake_redis).to receive(:unsubscribe).and_call_original
    fake_redis
  end

  def stub_call_platform_client(stream_sid: "stream-sid")
    instance_double(
      CallPlatform::Client,
      create_media_stream: CallPlatform::Client::AudioStreamResponse.new(id: stream_sid),
      notify_media_stream_event: nil
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
      event_handler: instance_spy(ExecuteConnect::EventHandler),
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
end
