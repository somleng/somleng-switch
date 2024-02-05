require "spec_helper"

module Rayo
  module Command
    module AudioFork
      RSpec.describe Start do
        def parse_stanza(xml)
          Nokogiri::XML.parse(xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS)
        end

        describe "#to_xml" do
          it "serializes to Rayo XML" do
            command = Start.new(
              uuid: "call-id",
              url: "wss://mystream.ngrok.io/audiostream",
              mix_type: "mono",
              sampling_rate: "16k"
            )

            xml = Hash.from_xml(command.to_xml)

            expect(xml.fetch("exec")).to include(
              "api" => "uuid_audio_fork",
              "args" => "call-id start wss://mystream.ngrok.io/audiostream mono 16k"
            )
          end
        end
      end
    end
  end
end
