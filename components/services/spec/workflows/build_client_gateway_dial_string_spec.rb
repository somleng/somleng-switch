require_relative "../spec_helper"

RSpec.describe BuildClientGatewayDialString, :client_gateway do
  it "builds a client gateway dial string" do
    create_location(
      username: "user1",
      contact: "sip:user1@45.118.77.153:9999;ob",
      socket: "udp:10.10.0.20:6060",
      last_modified: Time.now - 60
    )

    create_location(
      username: "user1",
      contact: "sip:user1@45.118.77.153:1634;ob",
      socket: "udp:10.10.0.20:6060",
      last_modified: Time.now
    )

    result = BuildClientGatewayDialString.call(
      destination: "016701722",
      client_identifier: "user1"
    )

    expect(result).to eq(dial_string: "016701722@45.118.77.153:1634;fs_path=sip:10.10.0.20:6060")
  end

  it "handles nated clients" do
    create_location(
      username: "user1",
      contact: "sip:user1@192.168.1.75:5060",
      received: "sip:45.118.77.153:1619",
      socket: "udp:10.10.0.20:6060"
    )

    result = BuildClientGatewayDialString.call(
      destination: "016701722",
      client_identifier: "user1"
    )

    expect(result).to eq(dial_string: "016701722@45.118.77.153:1619;fs_path=sip:10.10.0.20:6060")
  end

  it "handles unregistered clients" do
    result = BuildClientGatewayDialString.call(
      destination: "016701722",
      client_identifier: "user1"
    )

    expect(result).to eq(dial_string: nil)
  end
end
