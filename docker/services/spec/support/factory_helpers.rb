module FactoryHelpers
  def create_load_balancer_target(target_ip:)
    OpenSIPSLoadBalancerTarget.new(target_ip:).save!
  end

  def create_address(ip:)
    OpenSIPSAddress.new(ip:).save!
  end
end

RSpec.configure do |config|
  config.include(FactoryHelpers)
end
