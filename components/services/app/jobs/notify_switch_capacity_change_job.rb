class NotifySwitchCapacityChangeJob
  attr_reader :region, :cluster, :family, :ecs_client, :call_platform_client, :somleng_region

  def initialize(params, **options)
    params.transform_keys!(&:to_sym)
    @region = params.fetch(:region)
    @cluster = params.fetch(:cluster)
    @family = params.fetch(:family)
    @ecs_client = options.fetch(:ecs_client) { Aws::ECS::Client.new(region:) }
    @call_platform_client = options.fetch(:call_platform_client) { CallPlatform::Client.new }
    @somleng_region = options.fetch(:somleng_region) { SomlengRegion::Region.find_by!(identifier: region) }
  end

  def call
    call_platform_client.update_capacity(region: somleng_region.alias, capacity: tasks.count)
  end

  private

  def tasks
    @tasks ||= ecs_client.list_tasks(cluster:, family:).each_with_object([]) do |response, result|
      response.task_arns.each do |task_arn|
        result << task_arn
      end
    end
  end
end
