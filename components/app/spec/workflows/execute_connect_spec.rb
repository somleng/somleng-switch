require "spec_helper"

RSpec.describe ExecuteConnect, type: :call_controller do
  it "creates an Audio Stream" do
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
      redis_connection: -> { FakeRedis.new(default_subscription: stub_redis_subscription) },
      **build_workflow_options(
        context: controller,
        call_platform_client:,
        call_properties: { call_sid: "call-sid", account_sid: "account-sid" }
      )
    )

    expect(call_platform_client).to have_received(:create_audio_stream).with(
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
    redis_connection = FakeRedis.new
    redis_connection.publish_later(
      "mod_twilio_stream:stream-sid",
      { event: "disconnect" }.to_json
    )
    handled_events = []
    event_handler = ->(event) { handled_events << event }

    ExecuteConnect.call(
      verb,
      redis_connection: -> { redis_connection },
      **build_workflow_options(call_platform_client:, event_handler:)
    )

    expect(handled_events.first).to have_attributes(
      disconnect?: true
    )
  end

  def stub_redis_subscription
    fake_subscription = FakeRedis::DefaultSubscription.new
    allow(fake_subscription).to receive(:message)
    fake_subscription
  end

  def stub_call_platform_client(stream_sid: "stream-sid")
    call_platform_client = instance_double(
      CallPlatform::Client,
      create_audio_stream: CallPlatform::Client::AudioStreamResponse.new(id: stream_sid)
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
