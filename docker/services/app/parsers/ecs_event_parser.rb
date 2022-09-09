class ECSEventParser
  Event = Struct.new(
    :task_running?,
    :task_stopped?,
    :eni_attached?,
    :eni_deleted?,
    :eni_private_ip,
    :private_ip,
    :group,
    :event_type,
    keyword_init: true
  )

  attr_reader :event, :ecs_client, :ec2_client

  def initialize(event, ecs_client: Aws::ECS::Client.new, ec2_client: Aws::EC2::Client.new)
    @event = event
    @ecs_client = ecs_client
    @ec2_client = ec2_client
  end

  def parse_event
    Event.new(
      event_type: :ecs,
      task_running?: task_running?,
      task_stopped?: task_stopped?,
      eni_attached?: eni_attached?,
      eni_deleted?: eni_deleted?,
      eni_private_ip:,
      private_ip:,
      group:
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
    eni_private_ip || ec2_instance_private_ip
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
    detail.fetch("containerInstanceArn")
  end

  def cluster_arn
    detail.fetch("clusterArn")
  end

  def container_instance_details
    @container_instance_details ||= ecs_client.describe_container_instances(
      cluster: cluster_arn,
      container_instances: [
        container_instance_arn
      ]
    ).to_h
  end

  def ec2_instance_id
    container_instance_details.dig(:container_instances, 0, :ec2_instance_id)
  end

  def ec2_instance_details
    @ec2_instance_details ||= ec2_client.describe_instances(
      instance_ids: [ec2_instance_id]
    ).to_h
  end

  def ec2_instance_private_ip
    ec2_instance_details.dig(:reservations, 0, :instances, 0).fetch(:private_ip_address)
  end
end
