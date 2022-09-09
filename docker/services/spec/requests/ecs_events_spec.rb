require_relative "../spec_helper"

RSpec.describe "Handle ECS Events", :public_gateway, :client_gateway do
  context "Switch events" do
    it "handles load balancer targets" do
      stub_env("SWITCH_GROUP" => "service:somleng-switch")
      create_load_balancer_target(
        dst_uri: "sip:10.1.1.1:5060",
        resources: "gw=fs://:fs-event-socket-password@10.1.1.1:8021"
      )
      payload = build_ecs_event_payload(
        group: "service:somleng-switch",
        eni_private_ip: "10.1.1.100",
        eni_status: "ATTACHED",
        last_status: "RUNNING"
      )

      invoke_lambda(payload:)

      result = public_gateway_load_balancer.all
      expect(result.count).to eq(3)

      expect(result[0]).to include(
        dst_uri: "sip:10.1.1.1:5060",
        resources: "gw=fs://:fs-event-socket-password@10.1.1.1:8021"
      )
      expect(result[1]).to include(
        dst_uri: "sip:10.1.1.100:5060",
        resources: "gw=fs://:fs-event-socket-password@10.1.1.100:8021"
      )
      expect(result[2]).to include(
        dst_uri: "sip:10.1.1.100:5080",
        resources: "gwalt=fs://:fs-event-socket-password@10.1.1.100:8021"
      )

      expect(client_gateway_load_balancer.all.count).to eq(3)
    end

    it "only adds a load balancer target once" do
      stub_env("SWITCH_GROUP" => "service:somleng-switch")
      create_load_balancer_target(
        dst_uri: "sip:10.1.1.1:5060",
        resources: "gw=fs://:fs-event-socket-password@10.1.1.1:8021"
      )
      payload = build_ecs_event_payload(
        group: "service:somleng-switch",
        eni_private_ip: "10.1.1.1",
        eni_status: "ATTACHED",
        last_status: "RUNNING"
      )

      invoke_lambda(payload:)

      expect(public_gateway_load_balancer.count).to eq(1)
      expect(client_gateway_load_balancer.count).to eq(1)
    end

    it "removes load balancer targets" do
      stub_env("SWITCH_GROUP" => "service:somleng-switch")
      create_load_balancer_target(
        dst_uri: "sip:10.1.1.1:5060",
        resources: "gw=fs://:fs-event-socket-password@10.1.1.1:8021"
      )
      create_load_balancer_target(
        dst_uri: "sip:10.1.1.1:5080",
        resources: "gwalt=fs://:fs-event-socket-password@10.1.1.1:8021"
      )
      payload = build_ecs_event_payload(
        group: "service:somleng-switch",
        eni_private_ip: "10.1.1.1",
        eni_status: "DELETED",
        last_status: "STOPPED"
      )

      invoke_lambda(payload:)

      expect(public_gateway_load_balancer.count).to eq(0)
      expect(client_gateway_load_balancer.count).to eq(0)
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
  end

  def public_gateway_load_balancer
    public_gateway_database_connection.table(:load_balancer)
  end

  def client_gateway_load_balancer
    client_gateway_database_connection.table(:load_balancer)
  end
end
