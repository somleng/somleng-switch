module FactoryHelpers
  def create_load_balancer_target(dst_uri:, resources:, group_id: 1, probe_mode: 2)
    opensips_database_connection.exec(
      "INSERT INTO load_balancer (group_id, dst_uri, resources, probe_mode) VALUES (#{group_id}, '#{dst_uri}', '#{resources}', #{probe_mode});"
    )
  end
end

RSpec.configure do |config|
  config.include(FactoryHelpers)
end
