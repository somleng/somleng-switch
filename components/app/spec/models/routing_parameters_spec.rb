require "spec_helper"

RSpec.describe RoutingParameters do
  describe "#address" do
    it "builds an address" do
      routing_parameters = RoutingParameters.new(
        build_routing_parameters(
          destination: "855 (716) 100 987",
          dial_string_prefix: nil,
          plus_prefix: false,
          national_dialing: false,
          host: "sip.example.com"
        )
      )

      expect(routing_parameters.address).to eq("855716100987@sip.example.com")
    end

    it "builds an address for national dialing" do
      routing_parameters = RoutingParameters.new(
        build_routing_parameters(
          destination: "855 (716) 100 987",
          dial_string_prefix: nil,
          plus_prefix: false,
          national_dialing: true,
          host: "sip.example.com"
        )
      )

      expect(routing_parameters.address).to eq("0716100987@sip.example.com")
    end
  end

  describe "#format_number" do
    it "formats a number" do
      routing_parameters = RoutingParameters.new(
        build_routing_parameters(
          destination: "+855 (716) 100 987",
          dial_string_prefix: nil,
          plus_prefix: false,
          national_dialing: true,
          host: "sip.example.com"
        )
      )

      expect(routing_parameters.address).to eq("0716100987@sip.example.com")
    end
  end


  def build_routing_parameters(options)
    options.reverse_merge(
      destination: "855716100987",
      dial_string_prefix: nil,
      plus_prefix: false,
      national_dialing: false,
      host: "sip.example.com",
      username: nil
    )
  end
end
