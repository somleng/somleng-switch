class DeregisterOpenSIPSLoadBalancerTarget < ApplicationWorkflow
  attr_reader :load_balancer_target

  def initialize(target_ip:)
    @load_balancer_target = OpenSIPSLoadBalancerTarget.new(target_ip:)
  end

  def call
    delete_load_balancer_target
    ExecuteOpenSIPSCommand.call(:lb_reload)
  end

  private

  def delete_load_balancer_target
    database_connection.exec(
      "DELETE FROM load_balancer WHERE dst_uri='#{load_balancer_target.dst_uri}';"
    )
  end

  def database_connection
    @database_connection ||= DatabaseConnection.new(db_name: ENV.fetch("OPENSIPS_DB_NAME"))
  end
end
