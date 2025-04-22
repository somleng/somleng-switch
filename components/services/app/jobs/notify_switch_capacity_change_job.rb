class NotifySwitchCapacityChangeJob
  attr_reader :region, :cluster, :family, :ecs_client, :somleng_client, :somleng_region

  def initialize(params, **options)
    params.transform_keys!(&:to_sym)
    @region = params.fetch(:region)
    @cluster = params.fetch(:cluster)
    @family = params.fetch(:family)
    @ecs_client = options.fetch(:ecs_client) { Aws::ECS::Client.new(region:) }
    @somleng_client = options.fetch(:somleng_client) { Somleng::Client.new }
    @somleng_region = options.fetch(:somleng_region) { SomlengRegion::Region.find_by!(identifier: region) }
  end

  def call
    somleng_client.update_switch_capacity(region: somleng_region.alias, capacity: tasks.count)
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
