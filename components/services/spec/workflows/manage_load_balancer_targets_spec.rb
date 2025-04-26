require_relative "../spec_helper"

RSpec.describe ManageLoadBalancerTargets, :client_gateway, :public_gateway do
  it "Adds load balancer targets" do
    stub_env("FS_EVENT_SOCKET_PASSWORD" => "fs-event-socket-password")

    ManageLoadBalancerTargets.new(ip_address: "10.1.1.100").create_targets

    public_gateway_targets = public_gateway_load_balancer.all
    client_gateway_targets = client_gateway_load_balancer.all

    expect(public_gateway_targets.count).to eq(2)
    expect(client_gateway_targets.count).to eq(2)
    public_gateway_targets.each_with_index do |public_gateway_target, i|
      expect(
        public_gateway_target.slice(:dst_uri, :resources)
      ).to eq(client_gateway_targets[i].slice(:dst_uri, :resources))
    end

    expect(public_gateway_targets[0]).to include(
      dst_uri: "sip:10.1.1.100:5060",
      resources: "gw=fs://:fs-event-socket-password@10.1.1.100:8021"
    )
    expect(public_gateway_targets[1]).to include(
      dst_uri: "sip:10.1.1.100:5080",
      resources: "gwalt=fs://:fs-event-socket-password@10.1.1.100:8021"
    )
  end

  it "Only adds a load balancer target once" do
    stub_env("FS_EVENT_SOCKET_PASSWORD" => "fs-event-socket-password")
    create_load_balancer_target(
      dst_uri: "sip:10.1.1.100:5060",
      resources: "gw=fs://:fs-event-socket-password@10.1.1.100:8021"
    )
    create_load_balancer_target(
      dst_uri: "sip:10.1.1.100:5080",
      resources: "gwalt=fs://:fs-event-socket-password@10.1.1.100:8021"
    )

    ManageLoadBalancerTargets.new(ip_address: "10.1.1.100").create_targets

    expect(public_gateway_load_balancer.count).to eq(2)
    expect(client_gateway_load_balancer.count).to eq(2)
  end

  it "Deletes load balancer targets" do
    create_load_balancer_target(
      dst_uri: "sip:10.1.1.100:5060",
      resources: "gw=fs://:fs-event-socket-password@10.1.1.1:8021"
    )
    create_load_balancer_target(
      dst_uri: "sip:10.1.1.100:5080",
      resources: "gwalt=fs://:fs-event-socket-password@10.1.1.1:8021"
    )

    ManageLoadBalancerTargets.new(ip_address: "10.1.1.100").delete_targets

    expect(public_gateway_load_balancer.count).to eq(0)
    expect(client_gateway_load_balancer.count).to eq(0)
  end

  def public_gateway_load_balancer
    public_gateway_database_connection.table(:load_balancer)
  end

  def client_gateway_load_balancer
    client_gateway_database_connection.table(:load_balancer)
  end
end
