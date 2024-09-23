class HandleOpenSIPSLogEvent < ApplicationWorkflow
  LOAD_BALANCER_RESPONSE_ERROR_PATTERN = %r{\A(\d{3})-lb-response-error-(((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4})\z}
  TIMEOUT_ERROR_CODE = "408".freeze

  attr_reader :events, :error_tracking_client, :regions, :switch_group, :ecs_client, :ecs_task_finder

  LoadBalancerError = Struct.new(:target_ip, :code, keyword_init: true)

  def initialize(**options)
    @events = options.fetch(:event)
    @error_tracking_client = options.fetch(:error_tracking_client) { Sentry }
    @regions = options.fetch(:regions) { SomlengRegion::Region }
    @switch_group = options.fetch(:switch_group) { ENV.fetch("SWITCH_GROUP") }
    @ecs_client = options.fetch(:ecs_client) { Aws::ECS::Client.new }
    @ecs_task_finder = options.fetch(:ecs_task_finder) { FindECSTask }
  end

  def call
    load_balancer_timeout_errors = load_balancer_response_errors.select { |error| error.code == TIMEOUT_ERROR_CODE }
    affected_tasks = fetch_tasks_by_private_ip(load_balancer_timeout_errors.map(&:target_ip))
    stop_tasks(affected_tasks, reason: "Load balancer timeout detected")

    notify_errors
  end

  private

  def notify_errors
    error_tracking_client.capture_message(events.map(&:message).uniq.join("\n"))
  end

  def load_balancer_response_errors
    @load_balancer_response_errors ||= begin
      errors = events.select do |log|
        log.message.match?(LOAD_BALANCER_RESPONSE_ERROR_PATTERN)
      end

      errors.map do |log|
        code, ip, = LOAD_BALANCER_RESPONSE_ERROR_PATTERN.match(log.message).captures
        LoadBalancerError.new(target_ip: IPAddr.new(ip), code:)
      end
    end
  end

  def fetch_tasks_by_private_ip(target_ips)
    Array(target_ips).uniq.map do |target_ip|
      region = regions.all.find { |r| IPAddr.new(r.vpc_cidr).include?(target_ip) }

      ecs_task_finder.call(task_ip: target_ip, service_name: switch_group, region: region.identifier)
    end
  end

  def stop_tasks(tasks, reason:)
    Array(tasks).each do |task|
      with_aws_client(ecs_client, region: task.region) do |client|
        client.stop_task(cluster: task.cluster, task: task.arn, reason:)
      end
    end
  end

  def with_aws_client(client, region:)
    client.config.region = region
    yield(client)
  end
end
