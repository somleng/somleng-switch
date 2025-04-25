module FactoryHelpers
  def create_load_balancer_target(dst_uri:, resources:)
    public_gateway_database_connection.table(:load_balancer).insert(dst_uri:, resources:)
    client_gateway_database_connection.table(:load_balancer).insert(dst_uri:, resources:)
  end

  def create_address(**)
    public_gateway_database_connection.table(:address).insert(**)
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

  def build_ecs_event(**attributes)
    task_running = attributes.fetch(:task_running?, true)
    task_stopped = attributes.fetch(:task_stopped, !task_running)
    eni_attached = attributes.fetch(:eni_attached, task_running)
    eni_deleted = attributes.fetch(:eni_deleted, task_stopped)

    ECSEvent.new(
      event_type: :ecs,
      task_running?: task_running,
      task_stopped?: task_stopped,
      eni_attached?: eni_attached,
      eni_deleted?: eni_deleted,
      eni_private_ip: "10.0.0.139",
      private_ip: "10.0.0.139",
      public_ip: "54.251.92.249",
      group: "service:switch",
      family: "switch",
      region: "ap-southeast-1",
      cluster: "somleng-switch",
      **attributes
    )
  end
end

RSpec.configure do |config|
  config.include(FactoryHelpers)
end
