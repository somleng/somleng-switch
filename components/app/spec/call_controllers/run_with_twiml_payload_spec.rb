require "spec_helper"

RSpec.describe CallController, type: :call_controller do
  it "executes with the provided twiml payload" do
    controller = build_controller(
      stub_voice_commands: :play_audio,
      call_properties: {
        voice_url: nil,
        twiml: <<~TWIML
          <?xml version="1.0" encoding="UTF-8" ?>
          <Response>
            <Play>https://demo.twilio.com/docs/classic.mp3</Play>
          </Response>
        TWIML
      }
    )

    controller.run

    expect(controller).to have_received(:play_audio)
  end
end
