require_relative "../spec_helper"

RSpec.describe "Handle ECS Events", :client_gateway, :public_gateway do
  it "handles switch events" do
    stub_env("SWITCH_GROUP" => "service:somleng-switch")
    payload = build_ecs_event_payload(
      region: "us-east-1",
      group: "service:somleng-switch",
      eni_private_ip: "10.1.1.100",
      eni_status: "ATTACHED",
      last_status: "RUNNING"
    )

    invoke_lambda(payload:)

    expect(public_gateway_load_balancer.count).to eq(2)
    expect(client_gateway_load_balancer.count).to eq(2)
    expect(public_gateway_load_balancer.first).to include(
      group_id: 2
    )
  end

  it "handles client gateway events" do
    stub_env("CLIENT_GATEWAY_GROUP" => "service:client-gateway")

    payload = build_ecs_event_payload(
      group: "service:client-gateway",
      last_status: "RUNNING",
      attachments: []
    )

    invoke_lambda(payload:)

    expect(client_gateway_domains.count).to eq(2)
  end

  it "handles media proxy events" do
    stub_env("MEDIA_PROXY_GROUP" => "service:media-proxy")

    payload = build_ecs_event_payload(
      group: "service:media-proxy",
      last_status: "RUNNING",
      attachments: []
    )

    invoke_lambda(payload:)

    expect(rtpengine.count).to eq(1)
  end

  it "ignores events from other tasks" do
    stub_env("SWITCH_GROUP" => "service:somleng-switch")
    payload = build_ecs_event_payload(
      group: "service:somleng-switch-opensips"
    )

    invoke_lambda(payload:)
    expect(public_gateway_load_balancer.count).to eq(0)
    expect(client_gateway_load_balancer.count).to eq(0)
  end

  def public_gateway_load_balancer
    public_gateway_database_connection.table(:load_balancer)
  end

  def client_gateway_load_balancer
    client_gateway_database_connection.table(:load_balancer)
  end

  def client_gateway_domains
    client_gateway_database_connection.table(:domain)
  end

  def rtpengine
    client_gateway_database_connection.table(:rtpengine)
  end
end
