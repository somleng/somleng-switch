module SomlengRegions
  class << self
    def configure
      yield(configuration)
      configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end
    alias config configuration

    def regions
      @regions ||= Collection.new(Parser.new.parse(configuration.region_data))
    end
  end
end

require_relative "somleng_regions/configuration"
require_relative "somleng_regions/parser"
require_relative "somleng_regions/collection"
require_relative "somleng_regions/region"
