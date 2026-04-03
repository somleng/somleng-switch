require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  let(:call_sid) { "9802a301-aed5-41c8-b662-e3d3180a3eb4" }
  let(:account_sid) { "1b2ce123-cffc-4188-bdb6-d6a76ab10cf1" }
  let(:voice_url) { "https://demo.twilio.com/docs/voice.xml" }
  let(:voice_method) { "GET" }

  it "handles inbound calls from public gateway", :vcr, cassette: :inbound_call do
    call_sid = "9802a301-aed5-41c8-b662-e3d3180a3eb4"
    call = build_fake_call(
      variables: {
        "variable_somleng_call_sid" => call_sid,
        "variable_somleng_account_sid" => account_sid,
        "variable_somleng_voice_url" => voice_url,
        "variable_somleng_voice_method" => voice_method
      }
    )
    controller = CallController.new(call)
    stub_controller_voice_commands(controller, voice_commands: %i[say play_audio])

    controller.run

    expect(controller).to have_received(:answer).with(
      "X-Somleng-CallSid" => call_sid
    )
    expect(controller).to have_received(:say)
    expect(controller).to have_received(:play_audio).with("http://demo.twilio.com/docs/classic.mp3")
  end

  it "enables billing", :vcr, cassette: :inbound_call do
    call_id = SecureRandom.uuid
    call = build_fake_call(
      id: call_id,
      variables: {
        "variable_somleng_call_sid" => call_sid,
        "variable_somleng_account_sid" => account_sid,
        "variable_somleng_voice_url" => voice_url,
        "variable_somleng_voice_method" => voice_method,
        "variable_somleng_billing_enabled" => "true",
        "variable_somleng_billing_mode" => "prepaid"
      }
    )

    controller = CallController.new(call)
    stub_controller_voice_commands(controller, voice_commands: %i[say play_audio])
    controller.run

    expect(call).to have_received(:write_command) do |command|
      expect(command).to be_a(Rayo::Command::SetVar)
      expect(command).to have_attributes(
        uuid: call_id,
        name: "cgr_reqtype",
        value: "*prepaid"
      )
    end
  end
end
