require_relative "../spec_helper"

RSpec.describe "Handle Service Actions", :client_gateway do
  it "builds client gateway dial strings" do
    create_location(
      username: "user1",
      contact: "sip:user1@192.168.1.75:5060",
      received: "sip:45.118.77.153:1619",
      socket: "udp:10.10.0.20:6060"
    )

    payload = build_service_action_payload(
      service_action: "BuildClientGatewayDialString",
      parameters: {
        "client_identifier" => "user1",
        "destination" => "016701722"
      }
    )

    result = invoke_lambda(payload:)

    expect(result).to eq(
      {
        "dial_string" => "016701722@45.118.77.153:1619;fs_path=sip:10.10.0.20:6060"
      }.to_json
    )
  end
end
