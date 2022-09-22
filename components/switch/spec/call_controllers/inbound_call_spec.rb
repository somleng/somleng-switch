require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  it "handles inbound calls", :vcr, cassette: :inbound_call do
    call = build_fake_call(
      to: "1234",
      variables: { "variable_sip_network_ip" => "192.168.3.1" }
    )
    controller = CallController.new(call)
    stub_controller_voice_commands(controller, voice_commands: %i[say play_audio])

    controller.run

    expect(controller).to have_received(:answer).with(
      "X-Somleng-CallSid" => be_present,
      "X-Somleng-AccountSid" => be_present
    )
    expect(controller).to have_received(:say)
    expect(controller).to have_received(:play_audio)
  end
end
