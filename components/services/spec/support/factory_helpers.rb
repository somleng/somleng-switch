module FactoryHelpers
  def create_load_balancer_target(dst_uri:, resources:)
    public_gateway_database_connection.table(:load_balancer).insert(dst_uri:, resources:)
    client_gateway_database_connection.table(:load_balancer).insert(dst_uri:, resources:)
  end

  def create_address(ip:)
    public_gateway_database_connection.table(:address).insert(ip:)
  end

  def create_rtpengine_target(socket:)
    client_gateway_database_connection.table(:rtpengine).insert(socket:, set_id: 0)
  end

  def create_domain(domain:)
    client_gateway_database_connection.table(:domain).insert(domain:)
  end

  def create_location(params)
    params = {
      expires: (Time.now + 300).to_i
    }.merge(params)
    client_gateway_database_connection.table(:location).insert(params)
  end

  def create_subscriber(params)
    client_gateway_database_connection.table(:subscriber).insert(params)
  end
end

RSpec.configure do |config|
  config.include(FactoryHelpers)
end
