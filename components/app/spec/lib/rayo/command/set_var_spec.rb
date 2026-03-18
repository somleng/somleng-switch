require "spec_helper"

module Rayo
  module Command
    RSpec.describe SetVar do
      describe "#to_xml" do
        it "serializes to Rayo XML" do
          command = SetVar.new(uuid: "call-id", name: "cgr_reqtype", value: "*prepaid")

          xml = Hash.from_xml(command.to_xml)

          expect(xml.fetch("exec")).to include(
            "api" => "uuid_setvar",
            "args" => "call-id cgr_reqtype *prepaid"
          )
        end
      end
    end
  end
end
