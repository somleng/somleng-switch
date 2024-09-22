require_relative "../spec_helper"

RSpec.describe "Handle CloudWatch Log Events" do
  it "handles public gateway alerts" do
    stub_env("PUBLIC_GATEWAY_LOG_GROUP" => "public-gateway")
    payload = build_cloudwatch_log_event_payload(
      log_group: "public-gateway",
      log_events: [
        build_cloudwatch_log_event(
          message: build_opensips_message(message: "408-lb-response-error-10.10.1.180")
        )
      ]
    )

    invoke_lambda(payload:)
  end

  def build_opensips_message(data = {})
    data = {
      time: "Sep 22 07:24:26",
      pid: 82,
      level: "CRITICAL",
      message: "error"
    }.merge(data)

    {
      "time" => data.fetch(:time),
      "pid" => data.fetch(:pid),
      "level" => data.fetch(:level),
      "message" => data.fetch(:message)
    }.to_json
  end
end
