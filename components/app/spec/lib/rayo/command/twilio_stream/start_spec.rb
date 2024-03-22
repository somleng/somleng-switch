require "spec_helper"

module Rayo
  module Command
    module TwilioStream
      RSpec.describe Start do
        def parse_stanza(xml)
          Nokogiri::XML.parse(xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS)
        end

        it "is a server command" do
          command = Start.new
          command.domain = "mydomain"
          command.target_call_id = SecureRandom.uuid

          expect(command).to have_attributes(
            domain: nil,
            target_call_id: nil
          )
        end

        describe "#to_xml" do
          it "serializes to Rayo XML" do
            metadata = {
              call_sid: "call-sid",
              account_sid: "account-sid",
              stream_sid: "stream-sid",
              custom_parameters: {
                foo: "bar"
              }
            }.to_json

            command = Start.new(
              uuid: "call-id",
              url: "wss://mystream.ngrok.io/audiostream",
              metadata:
            )

            xml = Hash.from_xml(command.to_xml)

            expect(xml.fetch("exec")).to include(
              "api" => "uuid_twilio_stream",
              "args" => "call-id start wss://mystream.ngrok.io/audiostream #{Base64.strict_encode64(metadata)}"
            )
          end
        end
      end
    end
  end
end
