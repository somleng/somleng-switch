require_relative '../app/models/drb_endpoint'

Adhearsion.config do |config|
  config.development do |dev|
    dev.platform.logging.level = :debug
  end

  config.adhearsion_drb do |drb|
    drb.shared_object = DrbEndpoint.new
  end
end
