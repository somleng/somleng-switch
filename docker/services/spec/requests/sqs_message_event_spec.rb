require_relative "../spec_helper"

RSpec.describe "Handles SQS Message" do
  it "adds an address record" do
    payload = build_sqs_message_event_payload(
      event_source_arn: "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions",
      body: {
        "job_class" => "CreateOpenSIPSPermissionJob",
        "job_args" => ["165.57.32.1"]
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
    create_address(ip: "165.57.32.1")

    payload = build_sqs_message_event_payload(
      event_source_arn: "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions",
      body: {
        "job_class" => "DeleteOpenSIPSPermissionJob",
        "job_args" => ["165.57.32.1"]
      }.to_json
    )

    invoke_lambda(payload:)

    expect(address.count).to eq(0)
  end

  def address
    public_gateway_database_connection.table(:address)
  end
end
