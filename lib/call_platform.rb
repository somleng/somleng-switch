module CallPlatform
  class << self
    def configure
      yield(configuration)
      configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end
    alias config configuration
  end
end

require_relative "call_platform/configuration"
require_relative "call_platform/client"
