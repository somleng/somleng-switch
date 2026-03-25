require "spec_helper"

RSpec.describe DialString do
  describe "#to_s" do
    it "creates a dial string" do
      dial_string = DialString.new(
        build_options(
          routing_parameters: { destination: "855716100987", host: "sip.example.com" },
          fs_host: "localhost",
          fs_port: 5060
        )
      )

      expect(dial_string.to_s).to eq("{proxy_leg=true}sofia/uac_internal/855716100987@sip.example.com;fs_path=sip:localhost:5060")
    end

    it "sets channels variables" do
      dial_string = DialString.new(build_options)

      expect(dial_string.to_s).to start_with("{proxy_leg=true}")
    end

    it "uses the default profile" do
      dial_string = DialString.new(build_options(address: "1234@192.168.1.1"))

      expect(dial_string.to_s).to match(%r{sofia/uac_internal})
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

      expect(dial_string.to_s).to match(%r{sofia/uac_internal/855716100987@sip.example.com})
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

      expect(dial_string.to_s).to match(%r{sofia/uac_internal/\+1234855716100987@sip.example.com})
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

      expect(dial_string.to_s).to match(%r{sofia/uac_internal/0716100987@sip.example.com})
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

      expect(dial_string.to_s).to match(%r{sofia/uac_internal/6505130514@sip.example.com})
    end

    it "build a client gateway dial string" do
      fake_services_client = instance_double(
        Services::Client,
        build_client_gateway_dial_string:
        Services::Client::ClientGatewayResponse.new(
          destination_address: "02092960310@45.118.77.153:1619",
          proxy_address: "10.10.0.20:6060"
        )
      )

      dial_string = DialString.new(
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
      )

      expect(dial_string.to_s).to match(%r{sofia/uac_internal/102092960310@45.118.77.153:1619})
      expect(dial_string.proxy_address).to eq(";fs_path=sip:10.10.0.20:6060")
      expect(
        fake_services_client
      ).to have_received(
        :build_client_gateway_dial_string).with(username: "user1", destination: "02092960310"
      )
    end
  end

  describe "#external_profile" do
    it "returns the SIP profile from the routing parameters" do
      dial_string = DialString.new(build_options(routing_parameters: { sip_profile: "test" }))

      expect(dial_string.external_profile).to eq("test")
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
        build_options(
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
      address: nil,
      destination: "855716100987",
      dial_string_prefix: nil,
      plus_prefix: false,
      national_dialing: false,
      host: "sip.example.com",
      username: nil
    )

    billing_parameters.reverse_merge!(
      billing_mode: "prepaid"
    )

    {
      routing_parameters:,
      billing_parameters:,
      **options
    }
  end
end
