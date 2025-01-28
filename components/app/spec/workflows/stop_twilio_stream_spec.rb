require "spec_helper"

RSpec.describe StopTwilioStream, type: :call_controller do
  it "stops a twilio stream" do
    controller = build_controller(stub_voice_commands: :write_and_await_response)

    StopTwilioStream.call(controller)

    expect(controller).to have_received(:write_and_await_response).with(
      an_instance_of(Rayo::Command::TwilioStream::Stop)
    )
    expect(controller.call).to have_received(:write_command).with(
      have_attributes(
        class: Rayo::Command::UpdateCallProgress,
        flag: 0
      )
    )
  end
end
