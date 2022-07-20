require "spec_helper"

RSpec.describe DialString do
  describe "#to_s" do
    it "handles supported NAT trunks" do
      expect(
        DialString.new("1234@192.168.1.1", nat_supported: true).to_s
      ).to eq("sofia/external/1234@192.168.1.1")
    end

    it "handles unsupported NAT trunks" do
      expect(
        DialString.new("1234@192.168.1.1", nat_supported: false).to_s
      ).to eq("sofia/alternative-outbound/1234@192.168.1.1")
    end

    it "handles boolean strings" do
      expect(
        DialString.new("1234@192.168.1.1", nat_supported: "true").to_s
      ).to eq("sofia/external/1234@192.168.1.1")
      expect(
        DialString.new("1234@192.168.1.1", nat_supported: "false").to_s
      ).to eq("sofia/alternative-outbound/1234@192.168.1.1")
    end
  end
end
