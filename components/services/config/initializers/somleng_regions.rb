require "json"

SomlengRegions.configure do |config|
  config.region_data = AppSettings.fetch(:region_data)
  config.stub_regions = AppSettings.fetch(:stub_regions)
end
