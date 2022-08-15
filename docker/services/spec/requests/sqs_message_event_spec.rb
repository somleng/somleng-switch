require_relative "../spec_helper"

RSpec.describe "Handles SQS Message", :opensips do
  it "adds an address record" do
    stub_env("SWITCH_PERMISSIONS_QUEUE_ARN" => "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions")

    payload = build_sqs_message_event_payload(
      event_source_arn: "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions",
      body: {
        "action" => "add_permission",
        "source_ip" => "165.57.32.1"
      }.to_json
    )

    invoke_lambda(payload:)

    result = address.all
    expect(result.count).to eq(1)
    expect(result[0]).to include(
      ip: "165.57.32.1",
      grp: 0,
      mask: 32,
      port: 0,
      proto: "any"
    )
  end

  it "removes an address message" do
    stub_env("SWITCH_PERMISSIONS_QUEUE_ARN" => "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions")
    create_address(ip: "165.57.32.1")

    payload = build_sqs_message_event_payload(
      event_source_arn: "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions",
      body: {
        "action" => "remove_permission",
        "source_ip" => "165.57.32.1"
      }.to_json
    )

    invoke_lambda(payload:)

    expect(address.count).to eq(0)
  end

  def address
    opensips_database_connection.table(:address)
  end
end
