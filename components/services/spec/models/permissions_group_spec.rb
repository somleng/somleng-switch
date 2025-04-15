require "spec_helper"

RSpec.describe PermissionsGroup do
  it "handles permissions group bitmask" do
    expect(PermissionsGroup.new(region_code: 1).to_i).to eq(1)
    expect(PermissionsGroup.new(region_code: 0, symmetric_nat: true).to_i).to eq(64)
    expect(PermissionsGroup.new(region_code: 1, media_proxy: true).to_i).to eq(129)
  end
end
