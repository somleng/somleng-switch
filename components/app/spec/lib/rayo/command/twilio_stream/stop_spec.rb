require "spec_helper"

module Rayo
  module Command
    module TwilioStream
      RSpec.describe Stop do
        describe "#to_xml" do
          it "serializes to Rayo XML" do
            command = Stop.new(uuid: "call-id")

            xml = Hash.from_xml(command.to_xml)

            expect(xml.fetch("exec")).to include(
              "api" => "uuid_twilio_stream",
              "args" => "call-id stop"
            )
          end
        end
      end
    end
  end
end
