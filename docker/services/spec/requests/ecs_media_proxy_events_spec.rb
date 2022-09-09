require_relative "../spec_helper"

RSpec.describe "Handle ECS Media Proxy Events", :client_gateway do
  it "handles media proxy targets" do
    stub_env("MEDIA_PROXY_GROUP" => "service:media-proxy")
    create_rtpengine_target(socket: "udp:10.1.1.1:2223")

    payload = build_ecs_event_payload(
      group: "service:media-proxy",
      last_status: "RUNNING",
      attachments: []
    )

    invoke_lambda(payload:)

    result = rtpengine.all
    expect(result.count).to eq(2)

    expect(result[0].fetch(:socket)).to eq("udp:10.1.1.1:2223")
    # From AWS stubs
    expect(result[1].fetch(:socket)).to eq("udp:10.0.0.1:2223")
  end

  it "only adds a media proxy target once" do
    stub_env("MEDIA_PROXY_GROUP" => "service:media-proxy")
    # From AWS stubs
    create_rtpengine_target(socket: "udp:10.0.0.1:2223")

    payload = build_ecs_event_payload(
      group: "service:media-proxy",
      last_status: "RUNNING",
      attachments: []
    )

    invoke_lambda(payload:)

    expect(rtpengine.count).to eq(1)
  end

  it "removes media proxy targets" do
    stub_env("MEDIA_PROXY_GROUP" => "service:media-proxy")
    # From AWS stubs
    create_rtpengine_target(socket: "udp:10.0.0.1:2223")

    payload = build_ecs_event_payload(
      group: "service:media-proxy",
      last_status: "STOPPED",
      attachments: []
    )

    invoke_lambda(payload:)

    expect(rtpengine.count).to eq(0)
  end

  it "ignores events from other tasks" do
    stub_env("MEDIA_PROXY_GROUP" => "service:media-proxy")
    payload = build_ecs_event_payload(
      group: "service:other-service"
    )

    invoke_lambda(payload:)
    expect(rtpengine.count).to eq(0)
    expect(rtpengine.count).to eq(0)
  end

  def rtpengine
    client_gateway_database_connection.table(:rtpengine)
  end
end
