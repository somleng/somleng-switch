require_relative "../spec_helper"

RSpec.describe "Handles SQS Message" do
  it "adds an address record", :public_gateway do
    payload = build_sqs_message_event_payload(
      event_source_arn: "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions",
      body: {
        "job_class" => "CreateOpenSIPSPermissionJob",
        "job_args" => [ "165.57.32.1", { "group_id" => 1 } ]
      }.to_json
    )

    invoke_lambda(payload:)

    result = address.all
    expect(result.count).to eq(1)
    expect(result[0]).to include(
      ip: "165.57.32.1",
      grp: 1,
      mask: 32,
      port: 0,
      proto: "any"
    )
  end

  it "removes an address message", :public_gateway do
    create_address(ip: "165.57.32.1")

    payload = build_sqs_message_event_payload(
      event_source_arn: "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions",
      body: {
        "job_class" => "DeleteOpenSIPSPermissionJob",
        "job_args" => [ "165.57.32.1" ]
      }.to_json
    )

    invoke_lambda(payload:)

    expect(address.count).to eq(0)
  end

  it "updates an address message", :public_gateway do
    create_address(ip: "165.57.32.1", grp: 2)

    payload = build_sqs_message_event_payload(
      event_source_arn: "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions",
      body: {
        "job_class" => "UpdateOpenSIPSPermissionJob",
        "job_args" => [ "165.57.32.1", { "group_id" => 1 } ]
      }.to_json
    )

    invoke_lambda(payload:)

    result = address.all
    expect(result.count).to eq(1)
    expect(result[0]).to include(
      ip: "165.57.32.1",
      grp: 1
    )
  end

  it "adds a subscriber record", :client_gateway do
    payload = build_sqs_message_event_payload(
      event_source_arn: "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions",
      body: {
        "job_class" => "CreateOpenSIPSSubscriberJob",
        "job_args" => [
          {
            "username" => "user1",
            "md5_password" => "md5_password",
            "sha256_password" => "sha256_password",
            "sha512_password" => "sha512_password"
          }
        ]
      }.to_json
    )

    invoke_lambda(payload:)

    result = subscriber.all
    expect(result.count).to eq(1)
    expect(result[0]).to include(
      username: "user1",
      ha1: "md5_password",
      ha1_sha256: "sha256_password",
      ha1_sha512t256: "sha512_password"
    )
  end

  it "deletes a subscriber", :client_gateway do
    create_subscriber(username: "user1")

    payload = build_sqs_message_event_payload(
      event_source_arn: "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions",
      body: {
        "job_class" => "DeleteOpenSIPSSubscriberJob",
        "job_args" => [
          {
            "username" => "user1"
          }
        ]
      }.to_json
    )

    invoke_lambda(payload:)

    result = subscriber.all
    expect(result.count).to eq(0)
  end

  it "notifies switch capacity updates" do
    payload = build_sqs_message_event_payload(
      event_source_arn: "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions",
      body: {
        "job_class" => "NotifySwitchCapacityChangeJob",
        "job_args" => [
          {
            "region" => "ap-southeast-1",
            "cluster" => "somleng-switch",
            "family" => "switch"
          }
        ]
      }.to_json
    )

    stub_request(:post, "https://api.somleng.org/services/switch_capacities")

    invoke_lambda(payload:)

    expect(WebMock).to have_requested(:post, "https://api.somleng.org/services/switch_capacities").with(body: { region: "hydrogen", capacity: 0 }.to_json)
  end

  def subscriber
    client_gateway_database_connection.table(:subscriber)
  end

  def address
    public_gateway_database_connection.table(:address)
  end
end
