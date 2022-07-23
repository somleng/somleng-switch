require_relative "../spec_helper"
require "json"

RSpec.describe "Handle ECS Events", :opensips do
  it "adds load balancer targets" do
    stub_env("SWITCH_GROUP" => "service:somleng-switch")
    create_load_balancer_target(
      dst_uri: "sip:10.1.1.1:5060",
      resources: "pstn=fs://:fs-event-socket-password@10.1.1.1:8021"
    )
    payload = build_event_payload(
      group: "service:somleng-switch",
      eni_private_ip: "10.1.1.100",
      last_status: "RUNNING"
    )

    invoke_lambda(payload:)

    result = opensips_database_connection.exec("SELECT * FROM load_balancer;")
    expect(result.ntuples).to eq(2)
    expect(result[0]).to include(
      "dst_uri" => "sip:10.1.1.1:5060",
      "resources" => "pstn=fs://:fs-event-socket-password@10.1.1.1:8021"
    )
    expect(result[1]).to include(
      "dst_uri" => "sip:10.1.1.100:5060",
      "resources" => "pstn=fs://:fs-event-socket-password@10.1.1.100:8021"
    )
  end

  it "only adds a load balancer target once" do
    stub_env("SWITCH_GROUP" => "service:somleng-switch")
    create_load_balancer_target(
      dst_uri: "sip:10.1.1.1:5060",
      resources: "pstn=fs://:fs-event-socket-password@10.1.1.1:8021"
    )
    payload = build_event_payload(
      group: "service:somleng-switch",
      eni_private_ip: "10.1.1.1",
      last_status: "RUNNING"
    )

    invoke_lambda(payload:)

    result = opensips_database_connection.exec("SELECT * FROM load_balancer;")
    expect(result.ntuples).to eq(1)
  end

  it "removes load balancer targets" do
    stub_env("SWITCH_GROUP" => "service:somleng-switch")
    create_load_balancer_target(
      dst_uri: "sip:10.1.1.1:5060",
      resources: "pstn=fs://:fs-event-socket-password@10.1.1.1:8021"
    )
    payload = build_event_payload(
      group: "service:somleng-switch",
      eni_private_ip: "10.1.1.1",
      last_status: "STOPPED"
    )

    invoke_lambda(payload:)

    result = opensips_database_connection.exec("SELECT * FROM load_balancer;")
    expect(result.ntuples).to eq(0)
  end

  it "ignores events from other tasks" do
    stub_env("SWITCH_GROUP" => "service:somleng-switch-opensips")
    payload = build_event_payload(
      group: "service:somleng-switch-opensips"
    )

    result = opensips_database_connection.exec("SELECT * FROM load_balancer;")
    expect(result.ntuples).to eq(0)
    invoke_lambda(payload:)
  end

  def build_event_payload(data = {})
    data.reverse_merge!(
      eni_private_ip: "10.0.0.1",
      last_status: "RUNNING",
      group: "service:somleng-switch"
    )

    payload = JSON.parse(file_fixture("task_state_change_event.json").read)

    overrides = {
      "detail" => {
        "attachments" => [
          {
            "type" => "eni",
            "status" => "ATTACHED",
            "details" => [
              {
                "name" => "privateIPv4Address",
                "value" => data.fetch(:eni_private_ip)
              }
            ]
          }
        ],
        "lastStatus" => data.fetch(:last_status),
        "group" => data.fetch(:group)
      }
    }

    payload.deep_merge(overrides)
  end
end
