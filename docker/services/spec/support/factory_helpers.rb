module FactoryHelpers
  def create_load_balancer_target(dst_uri:, resources:)
    opensips_database_connection.table(:load_balancer).insert(dst_uri:, resources:)
  end

  def create_address(ip:)
    opensips_database_connection.table(:address).insert(ip:)
  end
end

RSpec.configure do |config|
  config.include(FactoryHelpers)
end
