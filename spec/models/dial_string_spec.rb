require "spec_helper"

RSpec.describe DialString do
  describe "#to_s" do
    it "handles trunks with symmetric latching support" do
      dial_string = DialString.new(symmetric_latching: true, address: "1234@192.168.1.1")

      expect(dial_string.to_s).to eq("sofia/external/1234@192.168.1.1")
    end

    it "handles trunks without symmetric latching support" do
      dial_string = DialString.new(symmetric_latching: false, address: "1234@192.168.1.1")

      expect(dial_string.to_s).to eq("sofia/alternative-outbound/1234@192.168.1.1")
    end

    it "builds a public gateway dial string" do
      dial_string = DialString.new(
        build_routing_parameters(
          destination: "855716100987",
          dial_string_prefix: nil,
          plus_prefix: false,
          trunk_prefix: false,
          host: "sip.example.com"
        )
      )

      expect(dial_string.to_s).to eq("sofia/external/855716100987@sip.example.com")
    end

    it "builds a dial string with dial string prefix" do
      dial_string = DialString.new(
        build_routing_parameters(
          destination: "855716100987",
          dial_string_prefix: "1234",
          plus_prefix: true,
          trunk_prefix: false,
          host: "sip.example.com"
        )
      )

      expect(dial_string.to_s).to eq("sofia/external/+1234855716100987@sip.example.com")
    end

    it "builds a dial string with trunk prefix" do
      dial_string = DialString.new(
        build_routing_parameters(
          destination: "855716100987",
          dial_string_prefix: nil,
          plus_prefix: false,
          trunk_prefix: true,
          host: "sip.example.com"
        )
      )

      expect(dial_string.to_s).to eq("sofia/external/0716100987@sip.example.com")
    end

    it "build a client gateway dial string" do
      fake_services_client = instance_double(
        Services::Client,
        build_client_gateway_dial_string: "855716100987@45.118.77.153:1619;fs_path=sip:10.10.0.20:6060"
      )

      result = DialString.new(
        build_routing_parameters(
          destination: "855716100987",
          username: "user1",
          plus_prefix: true,
          services_client: fake_services_client
        )
      ).to_s

      expect(result).to eq("sofia/external/+855716100987@45.118.77.153:1619;fs_path=sip:10.10.0.20:6060")
    end
  end

  def build_routing_parameters(options)
    options.reverse_merge(
      destination: "855716100987",
      dial_string_prefix: nil,
      plus_prefix: false,
      trunk_prefix: false,
      host: "sip.example.com",
      username: nil
    )
  end
end
