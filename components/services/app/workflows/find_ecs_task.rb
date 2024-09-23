class FindECSTask < ApplicationWorkflow
  attr_reader :task_ip, :service_name, :region, :ecs_client

  Task = Struct.new(:arn, :private_ip, :region, :cluster, keyword_init: true)

  def initialize(**options)
    @task_ip = options.fetch(:task_ip)
    @service_name = options.fetch(:service_name)
    @service_name = @service_name.delete_prefix("service:")
    @region = options[:region]
    @ecs_client = options.fetch(:ecs_client) { default_ecs_client }
  end

  def call
    find_task_by_private_ip
  end

  private

  def find_task_by_private_ip
    clusters.each do |cluster_arn|
      task_arns = list_tasks(cluster_arn:)

      next if task_arns.empty?

      describe_tasks(cluster_arn:, task_arns:).each do |task|
        next unless private_ip(task) == task_ip

        return Task.new(
          region: ecs_client.config.region,
          private_ip: task_ip,
          arn: task.task_arn,
          cluster: task.cluster_arn
        )
      end
    end

    nil
  end

  def clusters
    @clusters ||= ecs_client.list_clusters.cluster_arns
  end

  def list_tasks(cluster_arn:)
    ecs_client.list_tasks(cluster: cluster_arn, service_name:).task_arns
  end

  def describe_tasks(task_arns:, cluster_arn:)
    ecs_client.describe_tasks(tasks: task_arns, cluster: cluster_arn).tasks
  end

  def private_ip(task)
    eni = task.attachments.find { |attachment|  attachment.type == "ElasticNetworkInterface" }
    return if eni.nil?

    IPAddr.new(eni.details.find { |detail| detail.name == "privateIPv4Address" }.value)
  end

  def default_ecs_client
    region ? Aws::ECS::Client.new(region:) : Aws::ECS::Client.new
  end
end
