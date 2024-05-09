require "spec_helper"

RSpec.describe CallUpdateEventHandler do
  it "handles events" do
    event_handler = CallUpdateEventHandler.new

    event = event_handler.fake_event(
      voice_url: "https://www.example.com/redirect.xml",
      voice_method: "GET",
      twiml: nil
    )

    expect { event_handler.perform_now(event) }.to throw_symbol(
      :redirect,
      {
        url: "https://www.example.com/redirect.xml",
        http_method: "GET"
      }
    )
  end

  it "parses events" do
    event_payload = {
      id: "call-id",
      voice_url: "https://www.example.com/redirect.xml",
      voice_method: "POST",
      twiml: "<Response><Hangup/></Response>"
    }.to_json

    event = CallUpdateEventHandler.new.parse_event(event_payload)

    expect(event).to have_attributes(
      call_id: "call-id",
      voice_url: "https://www.example.com/redirect.xml",
      voice_method: "POST",
      twiml: "<Response><Hangup/></Response>"
    )
  end
end
