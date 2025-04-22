require "aws-sdk-sqs"

class HandleSwitchEvent < ApplicationWorkflow
  attr_reader :event, :regions, :load_balancer_manager, :queue_url, :sqs_client

  def initialize(event:, **options)
    super()
    @event = event
    @regions = options.fetch(:regions) { SomlengRegion::Region }
    @load_balancer_manager = options.fetch(:load_balancer_manager) { ManageLoadBalancerTargets.new(ip_address: event.private_ip) }
    @queue_url = options.fetch(:queue_url) { AppSettings.fetch(:queue_url) }
    @sqs_client = options.fetch(:sqs_client) { Aws::SQS::Client.new }
  end

  def call
    update_load_balancer_targets
    enqueue_notify
  end

  private

  def update_load_balancer_targets
    if task_running?
      load_balancer_manager.create_targets(group_id: load_balancer_group)
    elsif task_stopped?
      load_balancer_manager.delete_targets
    end
  end

  def enqueue_notify
    return if !task_running? && !task_stopped?

    enqueue_job(
      NotifySwitchCapacityChangeJob.to_s,
      region: event.region,
      cluster: event.cluster,
      family: event.family
    )
  end

  def enqueue_job(job_class, *args)
    sqs_client.send_message(
      queue_url:,
      message_body: {
        job_class:,
        job_args: args
      }.to_json
    )
  end

  def task_running?
    event.task_running? && event.eni_attached?
  end

  def task_stopped?
    event.task_stopped? && event.eni_deleted?
  end

  def load_balancer_group
    regions.find_by!(identifier: event.region).group_id
  end
end
