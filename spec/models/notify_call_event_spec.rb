require "spec_helper"

RSpec.describe NotifyCallEvent do
  it "notifies a call event", :vcr, cassette: :notify_call_event do
    event = Adhearsion::Event::End.new(
      headers: {
        "variable-uuid" => "5c8102f2-262a-418a-96b9-aa79789af621",
        "variable-answer_epoch" => "1607752961",
        "variable-sip_term_status" => "200"
      }
    )

    NotifyCallEvent.new(event).call

    expect(WebMock).to(have_requested(:post, %r{services/phone_call_events}).with { |request|
      JSON.parse(request.body) == {
        "type" => "completed",
        "phone_call" => "5c8102f2-262a-418a-96b9-aa79789af621",
        "variables" => {
          "sip_term_status" => "200",
          "answer_epoch" => "1607752961"
        }
      }
    })
  end
end
