Adhearsion.config do |config|
  config.development do |dev|
    dev.platform.logging.level = :debug
  end
#  config.drb do |config|
#    config.shared_object = DrbEndpoint
#  end
end
