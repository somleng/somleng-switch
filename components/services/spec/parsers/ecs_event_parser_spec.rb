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

  it "handles private instances" do
    ecs_client, ec2_client = stub_aws_clients(private_ip_address: "10.0.0.1", public_ip_address: nil)
    event = build_ecs_event_payload
    parser = ECSEventParser.new(event, ecs_client:, ec2_client:)

    result = parser.parse_event

    expect(result).to have_attributes(
      private_ip: "10.0.0.1",
      public_ip: nil
    )
  end

  it "requests to the correct regional endpoint" do
    ecs_client, ec2_client = stub_aws_clients(region: "ap-southeast-1")
    event = build_ecs_event_payload(region: "us-east-1")
    parser = ECSEventParser.new(event, ecs_client:, ec2_client:)

    parser.parse_event

    expect(ecs_client.api_requests.first.fetch(:context).client.config.region).to eq("us-east-1")
    expect(ec2_client.api_requests.first.fetch(:context).client.config.region).to eq("us-east-1")
  end

  it "handles public instances" do
    ecs_client, ec2_client = stub_aws_clients(private_ip_address: "10.0.0.1", public_ip_address: "54.251.92.249")
    event = build_ecs_event_payload
    parser = ECSEventParser.new(event, ecs_client:, ec2_client:)

    result = parser.parse_event

    expect(result).to have_attributes(
      private_ip: "10.0.0.1",
      public_ip: "54.251.92.249"
    )
  end

  def stub_aws_clients(options = {})
    ecs_client = Aws::ECS::Client.new(
      region: options.fetch(:region, "ap-southeast-1"),
      stub_responses: {
        describe_container_instances: {
          container_instances: [
            {
              ec2_instance_id: options.fetch(:ec2_instance_id, "ec2-instance-id")
            }
          ]
        }
      }
    )

    ec2_client = Aws::EC2::Client.new(
      region: options.fetch(:region, "ap-southeast-1"),
      stub_responses: {
        describe_instances: {
          reservations: [
            instances: [
              build_instance_data(options)
            ]
          ]
        }
      }
    )

    [ ecs_client, ec2_client ]
  end

  def build_instance_data(options)
    instance_data = options.fetch(:instance_data, {})
    instance_data[:private_ip_address] ||= options.fetch(:private_ip_address, "10.0.0.1")
    instance_public_ip = build_instance_public_ip(options)
    instance_data[:public_ip_address] ||= instance_public_ip unless instance_public_ip.nil?
    instance_data
  end

  def build_instance_public_ip(options)
    return if options.key?(:public_ip_address) && options.fetch(:public_ip_address).nil?

    options.fetch(:public_ip_address, "54.251.92.249")
  end
end
