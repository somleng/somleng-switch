require "spec_helper"

RSpec.describe StartTwilioStream, type: :call_controller do
  it "starts a twilio stream" do
    controller = build_controller(
      stub_voice_commands: :write_and_await_response,
      call: build_fake_call(id: "call-id")
    )

    StartTwilioStream.call(
      controller,
      call_properties: build_call_properties(call_sid: "call-sid", account_sid: "account-sid"),
      url: "wss://example.com/audio",
      stream_sid: "stream-sid",
      custom_parameters: {
        "foo" => "bar",
        "bar" => "baz"
      }
    )

    expect(controller).to have_received(:write_and_await_response).with(
      have_attributes(
        class: Rayo::Command::TwilioStream::Start,
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
    )
    expect(controller.call).to have_received(:write_command).with(
      have_attributes(
        class: Rayo::Command::UpdateCallProgress,
        flag: 1
      )
    )
  end
end
