require "spec_helper"

RSpec.describe OutboundCall do
  it "originates an outbound call" do
    call_params = build_call_params(
      "to" => "+85512334667",
      "from" => "2442",
      "voice_url" => "https://rapidpro.ngrok.com/handle/33/",
      "voice_method" => "GET",
      "status_callback_url" => "https://rapidpro.ngrok.com/handle/33/",
      "status_callback_method" => "POST",
      "twiml" => "twiml payload",
      "sid" => "sample-call-sid",
      "account_sid" => "sample-account-sid",
      "account_auth_token" => "sample-auth-token",
      "direction" => "outbound-api",
      "api_version" => "2010-04-01",
      "routing_instructions" => {
        "dial_string" => "85512334667@127.0.0.1"
      }
    )

    outbound_call = instance_double(Adhearsion::OutboundCall)
    allow(Adhearsion::OutboundCall).to receive(:originate).and_return(outbound_call)

    result = OutboundCall.new(call_params).initiate

    expect(result).to eq(outbound_call)
    expect(Adhearsion::OutboundCall).to have_received(:originate).with(
      "sofia/external/85512334667@127.0.0.1",
      from: "2442",
      controller: CallController,
      controller_metadata: {
        call_properties: CallProperties.new(
          voice_url: "https://rapidpro.ngrok.com/handle/33/",
          voice_method: "GET",
          twiml: "twiml payload",
          account_sid: "sample-account-sid",
          auth_token: "sample-auth-token",
          call_sid: "sample-call-sid",
          direction: "outbound-api",
          api_version: "2010-04-01",
          to: "+85512334667",
          from: "2442",
          sip_headers: SIPHeaders.new(
            call_sid: "sample-call-sid",
            account_sid: "sample-account-sid"
          )
        )
      },
      headers: {
        "X-Somleng-CallSid" => "sample-call-sid",
        "X-Somleng-AccountSid" => "sample-account-sid"
      }
    )
  end

  it "originates an outbound call without NAT support" do
    call_params = build_call_params(
      "routing_instructions" => {
        "dial_string" => "85512334667@127.0.0.1",
        "nat_supported" => false
      }
    )
    allow(Adhearsion::OutboundCall).to receive(:originate)

    OutboundCall.new(call_params).initiate

    expect(Adhearsion::OutboundCall).to have_received(:originate).with(
      "sofia/alternative-outbound/85512334667@127.0.0.1", any_args
    )
  end

  def build_call_params(params)
    params.reverse_merge(
      "to" => "+85512334667",
      "from" => "2442",
      "voice_url" => "https://rapidpro.ngrok.com/handle/33/",
      "voice_method" => "GET",
      "status_callback_url" => "https://rapidpro.ngrok.com/handle/33/",
      "status_callback_method" => "POST",
      "twiml" => "twiml payload",
      "sid" => "sample-call-sid",
      "account_sid" => "sample-account-sid",
      "account_auth_token" => "sample-auth-token",
      "direction" => "outbound-api",
      "api_version" => "2010-04-01",
      "routing_instructions" => {
        "dial_string" => "85512334667@127.0.0.1",
        "nat_supported" => false
      }
    )
  end
end
