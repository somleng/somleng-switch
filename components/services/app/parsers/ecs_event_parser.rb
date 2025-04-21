require "aws-sdk-ecs"
require "aws-sdk-ec2"

class ECSEventParser
  attr_reader :event, :ecs_client, :ec2_client

  def initialize(event, ecs_client: Aws::ECS::Client.new, ec2_client: Aws::EC2::Client.new)
    @event = event
    @ecs_client = ecs_client
    @ec2_client = ec2_client
  end

  def parse_event
    ECSEvent.new(
      event_type: :ecs,
      task_running?: task_running?,
      task_stopped?: task_stopped?,
      eni_attached?: eni_attached?,
      eni_deleted?: eni_deleted?,
      eni_private_ip:,
      private_ip:,
      public_ip:,
      group:,
      region:
    )
  end

  private

  def last_status
    detail.fetch("lastStatus")
  end

  def task_running?
    last_status == "RUNNING"
  end

  def task_stopped?
    last_status == "STOPPED"
  end

  def eni_attached?
    eni["status"] == "ATTACHED"
  end

  def eni_deleted?
    eni["status"] == "DELETED"
  end

  def group
    detail.fetch("group")
  end

  def eni_private_ip
    eni_private_ip_details["value"]
  end

  def eni_private_ip_details
    eni_details.find { |detail| detail.fetch("name") == "privateIPv4Address" } || {}
  end

  def private_ip
    return eni_private_ip unless eni_private_ip.nil?

    ec2_instance_private_ip unless container_instance_arn.nil?
  end

  def public_ip
    ec2_instance_public_ip unless container_instance_arn.nil?
  end

  def eni_details
    eni.fetch("details", {})
  end

  def eni
    attachments.find { |attachment| attachment.fetch("type") == "eni" } || {}
  end

  def detail
    event.fetch("detail")
  end

  def attachments
    detail.fetch("attachments")
  end

  def container_instance_arn
    detail["containerInstanceArn"]
  end

  def cluster_arn
    detail.fetch("clusterArn")
  end

  def region
    event.fetch("region")
  end

  def container_instance_details
    @container_instance_details ||= with_aws_client(ecs_client, region:) do |client|
      client.describe_container_instances(
        cluster: cluster_arn,
        container_instances: [
          container_instance_arn
        ]
      ).to_h
    end
  end

  def ec2_instance_id
    container_instance_details.dig(:container_instances, 0, :ec2_instance_id)
  end

  def ec2_instance_details
    @ec2_instance_details ||= with_aws_client(ec2_client, region:) do |client|
      client.describe_instances(
        instance_ids: [ ec2_instance_id ]
      ).to_h
    end
  end

  def ec2_instance_private_ip
    ec2_instance_details.dig(:reservations, 0, :instances, 0, :private_ip_address)
  end

  def ec2_instance_public_ip
    ec2_instance_details.dig(:reservations, 0, :instances, 0, :public_ip_address)
  end

  def with_aws_client(client, region:)
    client.config.region = region
    yield(client)
  end
end
