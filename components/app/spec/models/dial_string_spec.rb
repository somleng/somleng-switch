require "spec_helper"

RSpec.describe DialString do
  describe "#to_s" do
    it "handles trunks with symmetric latching support" do
      dial_string = DialString.new(build_options(routing_parameters: { symmetric_latching: true }, address: "1234@192.168.1.1"))

      expect(dial_string.to_s).to match("sofia/external/1234@192.168.1.1")
    end

    it "handles trunks without symmetric latching support" do
      dial_string = DialString.new(build_options(routing_parameters: { symmetric_latching: false }, address: "1234@192.168.1.1"))

      expect(dial_string.to_s).to match("sofia/alternative-outbound/1234@192.168.1.1")
    end

    it "sets channels variables" do
      dial_string = DialString.new(build_options(billing_parameters: { charging_mode: "postpaid" }, address: "1234@192.168.1.1"))

      expect(dial_string.to_s).to eq("{cgr_reqtype=*postpaid,cgr_flags=*resources;*attributes;*sessions;*routes;*thresholds;*stats;*accounts}sofia/external/1234@192.168.1.1")
    end

    it "builds a public gateway dial string" do
      dial_string = DialString.new(
        build_options(
          routing_parameters: {
            destination: "855716100987",
            dial_string_prefix: nil,
            plus_prefix: false,
            national_dialing: false,
            host: "sip.example.com"
          }
        )
      )

      expect(dial_string.to_s).to match("sofia/external/855716100987@sip.example.com")
    end

    it "builds a dial string with a plus prefix" do
      dial_string = DialString.new(
        build_options(
          routing_parameters: {
            destination: "855716100987",
            dial_string_prefix: "1234",
            plus_prefix: true,
            national_dialing: false,
            host: "sip.example.com"
          }
        )
      )

      expect(dial_string.to_s).to match(%r{sofia/external/\+1234855716100987@sip.example.com})
    end

    it "builds a dial string for national dialing for countries with a trunk prefix" do
      dial_string = DialString.new(
        build_options(
          routing_parameters: {
            destination: "855716100987",
            dial_string_prefix: nil,
            plus_prefix: false,
            national_dialing: true,
            host: "sip.example.com"
          }
        )
      )

      expect(dial_string.to_s).to match("sofia/external/0716100987@sip.example.com")
    end

    it "builds a dial string for national dialing for countries without a trunk prefix" do
      dial_string = DialString.new(
        build_options(
          routing_parameters: {
            destination: "16505130514",
            dial_string_prefix: nil,
            plus_prefix: false,
            national_dialing: true,
            host: "sip.example.com"
          }
        )
      )

      expect(dial_string.to_s).to match("sofia/external/6505130514@sip.example.com")
    end

    it "build a client gateway dial string" do
      fake_services_client = instance_double(
        Services::Client,
        build_client_gateway_dial_string: "02092960310@45.118.77.153:1619;fs_path=sip:10.10.0.20:6060"
      )

      result = DialString.new(
        build_options(
          routing_parameters: {
            destination: "8562092960310",
            username: "user1",
            plus_prefix: false,
            dial_string_prefix: "1",
            national_dialing: true,
            services_client: fake_services_client
          }
        )
      ).to_s

      expect(
        fake_services_client
      ).to have_received(
        :build_client_gateway_dial_string).with(username: "user1", destination: "02092960310"
      )
      expect(result).to match("sofia/external/102092960310@45.118.77.153:1619;fs_path=sip:10.10.0.20:6060")
    end
  end

  describe "#format_number" do
    it "formats a number in national format" do
      dial_string = DialString.new(
        build_options(
          routing_parameters: {
            national_dialing: true
          }
        )
      )

      result = dial_string.format_number("+855 (716)-100-987")

      expect(result).to eq("0716100987")
    end

    it "formats a number in national format for countries without a trunk prefix" do
      dial_string = DialString.new(
        build_options(
          routing_parameters: {
            national_dialing: true
          }
        )
      )

      result = dial_string.format_number("+16505130514")

      expect(result).to eq("6505130514")
    end

    it "formats a number in E.164 format" do
      dial_string = DialString.new(
        build_options(
          routing_parameters: {
            national_dialing: false,
            plus_prefix: true
          }
        )
      )

      result = dial_string.format_number("+855 (716)-100-987")

      expect(result).to eq("+855716100987")
    end

    it "formats a short code" do
      dial_string = DialString.new(
        build_routing_parameters(
          national_dialing: false,
          plus_prefix: true
        )
      )

      result = dial_string.format_number("1393")

      expect(result).to eq("1393")
    end
  end

  def build_options(routing_parameters: {}, billing_parameters: {}, **options)
    routing_parameters.reverse_merge!(
      destination: "855716100987",
      dial_string_prefix: nil,
      plus_prefix: false,
      national_dialing: false,
      host: "sip.example.com",
      username: nil
    )

    billing_parameters.reverse_merge!(
      charging_mode: "postpaid"
    )

    {
      routing_parameters:,
      billing_parameters:,
      **options
    }
  end
end
