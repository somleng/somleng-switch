require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  it "handles inbound calls from public gateway", :vcr, cassette: :inbound_call do
    call_sid = "9802a301-aed5-41c8-b662-e3d3180a3eb4"
    call = build_fake_call(
      to: '"1294" <sip:1294@52.74.4.205;transport=udp;user=phone>',
      from: '"0715100960" <sip:0715100960@52.74.4.205;transport=udp;user=phone>;tag=gK04468a89',
      variables: {
        "variable_somleng_call_sid" => call_sid,
        "variable_somleng_account_sid" => "1b2ce123-cffc-4188-bdb6-d6a76ab10cf1",
        "variable_somleng_voice_url" => "https://demo.twilio.com/docs/voice.xml",
        "variable_somleng_voice_method" => "GET",
        "variable_sip_h_x_somleng_caller_identity" => "0715100960",
        "variable_sip_h_x_somleng_callee_identity" => "1294",
        "variable_sip_network_ip" => "10.0.0.1",
        "variable_sip_h_x_src_ip" => "27.109.112.141"
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
end
