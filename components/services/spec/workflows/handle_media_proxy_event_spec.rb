require_relative "../spec_helper"

RSpec.describe HandleMediaProxyEvent, :client_gateway do
  it "Adds media proxy targets" do
    event = ECSEventParser::Event.new(task_running?: true, private_ip: "10.0.0.1")

    HandleMediaProxyEvent.call(event:)

    result = rtpengine.all
    expect(result.count).to eq(1)
    expect(result[0].fetch(:socket)).to eq("udp:10.0.0.1:2223")
  end

  it "Only adds media proxy targets once" do
    create_rtpengine_target(socket: "udp:10.0.0.1:2223")
    event = ECSEventParser::Event.new(task_running?: true, private_ip: "10.0.0.1")

    HandleMediaProxyEvent.call(event:)

    result = rtpengine.all
    expect(result.count).to eq(1)
  end

  it "Deletes media proxy targets" do
    create_rtpengine_target(socket: "udp:10.0.0.1:2223")
    event = ECSEventParser::Event.new(task_stopped?: true, private_ip: "10.0.0.1")

    HandleMediaProxyEvent.call(event:)

    result = rtpengine.all
    expect(result.count).to eq(0)
  end

  def rtpengine
    client_gateway_database_connection.table(:rtpengine)
  end
end
