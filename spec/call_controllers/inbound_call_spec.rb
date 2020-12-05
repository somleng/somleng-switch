require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  it "handles inbound calls" do
    call = build_fake_call
    controller = CallController.new(call)

    controller.run

    expect(controller).to have_received(:hangup)
  end
end
