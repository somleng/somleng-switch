require_relative "../spec_helper"

RSpec.describe ECSEventParser do
  it "parses an ECS event" do
    event = build_ecs_event_payload(
      group: "service:somleng-switch",
      eni_private_ip: "10.0.0.1",
      last_status: "RUNNING"
    )
    parser = ECSEventParser.new(event)

    result = parser.parse_event

    expect(result).to have_attributes(
      group: "service:somleng-switch",
      eni_private_ip: "10.0.0.1",
      task_running?: true
    )
  end

  it "handles stopped events" do
    event = build_ecs_event_payload(
      last_status: "STOPPED"
    )
    parser = ECSEventParser.new(event)

    result = parser.parse_event

    expect(result).to have_attributes(
      task_running?: false,
      task_stopped?: true
    )
  end

  it "handles events with no attachments" do
    event = build_ecs_event_payload(
      attachments: []
    )
    parser = ECSEventParser.new(event)

    result = parser.parse_event

    expect(result).to have_attributes(
      eni_private_ip: nil,
      eni_attached?: false
    )
  end

  it "handles events with precreated eni attachments" do
    event = build_ecs_event_payload(
      eni_status: "PRECREATED",
      attachment_details: [
        {
          "name" => "subnetId",
          "value" => "subnet-abcd"
        }
      ]
    )
    parser = ECSEventParser.new(event)

    result = parser.parse_event

    expect(result).to have_attributes(
      eni_private_ip: nil,
      eni_attached?: false
    )
  end

  it "handles events with attached eni attachments" do
    event = build_ecs_event_payload(
      eni_private_ip: "10.0.0.1",
      eni_status: "ATTACHED"
    )
    parser = ECSEventParser.new(event)

    result = parser.parse_event

    expect(result).to have_attributes(
      eni_private_ip: "10.0.0.1",
      eni_attached?: true,
      eni_deleted?: false
    )
  end

  it "handles events with deleted eni attachments" do
    event = build_ecs_event_payload(
      eni_private_ip: "10.0.0.1",
      eni_status: "DELETED"
    )
    parser = ECSEventParser.new(event)

    result = parser.parse_event

    expect(result).to have_attributes(
      eni_private_ip: "10.0.0.1",
      eni_attached?: false,
      eni_deleted?: true
    )
  end
end
