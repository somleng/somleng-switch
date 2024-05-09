require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  it "handles inbound calls from public gateway", :vcr, cassette: :inbound_call do
    call = build_fake_call(
      to: '"1294" <sip:1294@52.74.4.205;transport=udp;user=phone>',
      from: '"0715100960" <sip:0715100960@52.74.4.205;transport=udp;user=phone>;tag=gK04468a89',
      variables: {
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
      "X-Somleng-CallSid" => be_present,
      "X-Somleng-AccountSid" => be_present
    )
    expect(controller).to have_received(:say)
    expect(controller).to have_received(:play_audio)
    expect(WebMock).to(have_requested(:post, "http://api.lvh.me:3000/services/inbound_phone_calls").with { |request|
      request_body = JSON.parse(request.body)
      expect(request_body).to include(
        "from" => "0715100960",
        "external_id" => call.id,
        "host" => be_present
      )
    })
  end

  it "handles inbound calls from client gateway", :vcr, cassette: :inbound_call do
    call = build_fake_call(
      to: '"016243111" <sip:016243111@192.168.0.75;transport=udp;user=phone>',
      from: '"user1" <sip:user1@192.168.0.75;transport=udp;user=phone>;tag=gK04468a89',
      variables: {
        "variable_sip_h_x_somleng_client_identifier" => "user1",
        "variable_sip_h_x_somleng_caller_identity" => "0715100960", # from Remote Party ID Header
        "variable_sip_h_x_somleng_callee_identity" => "016243111",
        "variable_sip_network_ip" => "10.0.0.1"
      }
    )

    controller = CallController.new(call)
    stub_controller_voice_commands(controller, voice_commands: %i[say play_audio])

    controller.run

    expect(WebMock).to(have_requested(:post, "http://api.lvh.me:3000/services/inbound_phone_calls").with { |request|
    request_body = JSON.parse(request.body)
    expect(request_body).to include(
      "client_identifier" => "user1"
    )
  })
  end
end
