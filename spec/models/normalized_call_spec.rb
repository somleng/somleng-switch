require "spec_helper"

RSpec.describe NormalizedCall do
  describe "#from" do
    it "normalizes a simple number" do
      phone_call = build_phone_call(from: "85516701721")

      call = NormalizedCall.new(phone_call)

      expect(call.from).to eq("85516701721")
    end

    it "normalizes sip_p_asserted_identity number" do
      phone_call = build_phone_call(
        from: "<invalid@127.0.0.1>",
        variables: { "variable_sip_p_asserted_identity" => "85510212050" }
      )

      call = NormalizedCall.new(phone_call)

      expect(call.from).to eq("85510212050")
    end

    it "normalizes an invalid number" do
      phone_call = build_phone_call(
        from: "<invalid@127.0.0.1>",
        variables: { "variable_sip_p_asserted_identity" => "invalid-sip-address" }
      )

      call = NormalizedCall.new(phone_call)

      expect(call.from).to eq("invalid")
    end
  end

  describe "#to" do
    it "normalizes to number" do
      phone_call = build_phone_call(to: "85512345678")

      call = NormalizedCall.new(phone_call)

      expect(call.to).to eq("85512345678")
    end
  end

  describe "normalize numbers" do
    it "normalizes a simple number" do
      phone_call = build_phone_call(from: "85516701721")

      call = NormalizedCall.new(phone_call)

      expect(call.from).to eq("85516701721")
    end

    it "normalizes a simple number with plus" do
      phone_call = build_phone_call(from: "+85516701721")

      call = NormalizedCall.new(phone_call)

      expect(call.from).to eq("85516701721")
    end

    it "normalizes an address" do
      phone_call = build_phone_call(from: "<85516701721@127.0.0.1>")

      call = NormalizedCall.new(phone_call)

      expect(call.from).to eq("85516701721")
    end

    it "normalizes a SIP address" do
      phone_call = build_phone_call(from: "sip:85516701721@127.0.0.1:5060")

      call = NormalizedCall.new(phone_call)

      expect(call.from).to eq("85516701721")
    end

    it "normalizes a dial string" do
      phone_call = build_phone_call(
        to: "sofia/gateway/pin_kh_01/85512345678"
      )

      call = NormalizedCall.new(phone_call)

      expect(call.to).to eq("85512345678")
    end
  end

  def build_phone_call(options = {})
    options.reverse_merge!(
      variables: {}
    )

    instance_double(Adhearsion::Call, options)
  end
end
