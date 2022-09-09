require_relative "../spec_helper"

RSpec.describe "Handle ECS Client Gateway Events", :client_gateway do
  it "handles client gateway targets" do
    stub_env("CLIENT_GATEWAY_GROUP" => "service:client-gateway")
    create_domain(domain: "10.1.1.1")
    create_domain(domain: "54.251.92.1")

    payload = build_ecs_event_payload(
      group: "service:client-gateway",
      last_status: "RUNNING",
      attachments: []
    )

    invoke_lambda(payload:)

    result = domain.all
    expect(result.count).to eq(4)

    expect(result[0].fetch(:domain)).to eq("10.1.1.1")
    expect(result[1].fetch(:domain)).to eq("54.251.92.1")
    # From AWS stubs
    expect(result[2].fetch(:domain)).to eq("10.0.0.1")
    expect(result[3].fetch(:domain)).to eq("54.251.92.249")
  end

  it "only adds a media proxy target once" do
    stub_env("CLIENT_GATEWAY_GROUP" => "service:client-gateway")
    # From AWS stubs
    create_domain(domain: "10.0.0.1")
    create_domain(domain: "54.251.92.249")

    payload = build_ecs_event_payload(
      group: "service:client-gateway",
      last_status: "RUNNING",
      attachments: []
    )

    invoke_lambda(payload:)

    expect(domain.count).to eq(2)
  end

  it "removes media proxy targets" do
    stub_env("CLIENT_GATEWAY_GROUP" => "service:client-gateway")
    # From AWS stubs
    create_domain(domain: "10.0.0.1")
    create_domain(domain: "54.251.92.249")

    payload = build_ecs_event_payload(
      group: "service:client-gateway",
      last_status: "STOPPED",
      attachments: []
    )

    invoke_lambda(payload:)

    expect(domain.count).to eq(0)
  end

  it "ignores events from other tasks" do
    stub_env("CLIENT_GATEWAY_GROUP" => "service:client-gateway")
    payload = build_ecs_event_payload(
      group: "service:other-service"
    )

    invoke_lambda(payload:)
    expect(domain.count).to eq(0)
    expect(domain.count).to eq(0)
  end

  def domain
    client_gateway_database_connection.table(:domain)
  end
end
