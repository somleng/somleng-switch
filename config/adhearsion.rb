require_relative '../app/models/drb_endpoint'

Adhearsion.config do |config|
  config.adhearsion_drb do |drb|
    drb.shared_object = DrbEndpoint.new
  end
end
