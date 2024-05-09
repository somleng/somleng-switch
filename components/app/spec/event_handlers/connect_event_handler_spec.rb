require "spec_helper"

describe ConnectEventHandler do
  it "handles events" do
    call_platform_client = stub_call_platform_client
    event_handler = ConnectEventHandler.new(call_platform_client:)
    event = event_handler.fake_event(type: "connect_failed", stream_sid: "stream-sid")

    event_handler.perform_now(event)

    expect(call_platform_client).to have_received(
      :notify_media_stream_event
    ).with(media_stream_id: "stream-sid", event: { type: "connect_failed" })
  end

  it "parses events" do
    event_payload = { event: "connect_failed", streamSid: "stream-sid" }.to_json

    event = ConnectEventHandler.new.parse_event(event_payload)

    expect(event).to have_attributes(
      type: "connect_failed",
      disconnect?: true,
      stream_sid: "stream-sid"
    )
  end

  def stub_call_platform_client(stream_sid: "stream-sid")
    instance_double(
      CallPlatform::Client,
      notify_media_stream_event: nil
    )
  end
end
