require "spec_helper"

RSpec.describe DisconnectTwilioStream, type: :call_controller do
  it "disconnects a twilio stream" do
    controller = build_controller

    DisconnectTwilioStream.call(controller)

    expect(controller.call).to have_received(:write_command).with(
      have_attributes(
        class: Rayo::Command::UpdateCallProgress,
        flag: 0
      )
    )
  end
end
