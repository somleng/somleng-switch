require "spec_helper"

module Rayo
  module Command
    RSpec.describe UpdateCallProgress do
      describe "#to_xml" do
        it "serializes to Rayo XML" do
          xml = Hash.from_xml(UpdateCallProgress.new(flag: 1).to_xml)
          expect(xml.fetch("call_progress")).to include("flag" => "1")

          xml = Hash.from_xml(UpdateCallProgress.new(flag: 0).to_xml)
          expect(xml.fetch("call_progress")).to include("flag" => "0")
        end
      end
    end
  end
end
