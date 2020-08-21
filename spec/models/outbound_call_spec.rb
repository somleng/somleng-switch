require "spec_helper"

RSpec.describe OutboundCall do
  it "initiates an outbound call" do
    params = generate_call_params(
      "to" => "+85512334667",
      "from" => "2442",
      "voice_url" => "https://rapidpro.ngrok.com/handle/33/",
      "voice_method" => "GET",
      "status_callback_url" => "https://rapidpro.ngrok.com/handle/33/",
      "status_callback_method" => "POST",
      "sid" => "sample-call-sid",
      "account_sid" => "sample-account-sid",
      "account_auth_token" => "sample-auth-token",
      "direction" => "outbound-api",
      "api_version" => "2010-04-01",
      "routing_instructions" => {
        "source" => "2442",
        "destination" => "+85512334667",
        "dial_string_format" => "sip/%{dial_string_path}/%{gateway_type}/%{gateway}/%{destination}@%{destination_host}/%{address}",
        "gateway_type" => "external",
        "gateway" => "my_gateway",
        "destination_host" => "somleng.io",
        "address" => "012345678",
        "dial_string_path" => "path/to/dial_string"
      }
    )

    outbound_call = instance_double(Adhearsion::OutboundCall)
    allow(Adhearsion::OutboundCall).to receive(:originate).and_return(outbound_call)

    result = OutboundCall.new(call_params: params).initiate

    expect(result).to eq(outbound_call)
    expect(Adhearsion::OutboundCall).to have_received(:originate).with(
      "sip/path/to/dial_string/external/my_gateway/+85512334667@somleng.io/012345678",
      from: "2442",
      controller: CallController,
      controller_metadata: {
        voice_request_url: "https://rapidpro.ngrok.com/handle/33/",
        voice_request_method: "GET",
        account_sid: "sample-account-sid",
        auth_token: "sample-auth-token",
        call_sid: "sample-call-sid",
        adhearsion_twilio_to: "+85512334667",
        adhearsion_twilio_from: "+2442",
        direction: "outbound-api",
        api_version: "2010-04-01",
        rest_api_enabled: false
      }
    )
  end

  it "does not initiate an outbound call if disable originate is set to 1" do
    params = generate_call_params(
      "routing_instructions" => { "disable_originate" => "1" }
    )

    result = OutboundCall.new(call_params: params).initiate

    expect(result).to eq(nil)
  end

  def generate_call_params(options = {})
    {
      "to" => "+85512334667",
      "from" => "2442",
      "voice_url" => "https://rapidpro.ngrok.com/handle/33/",
      "voice_method" => "GET",
      "status_callback_url" => "https://rapidpro.ngrok.com/handle/33/",
      "status_callback_method" => "POST",
      "sid" => "sample-call-sid",
      "account_sid" => "sample-account-sid",
      "account_auth_token" => "sample-auth-token",
      "direction" => "outbound-api",
      "api_version" => "2010-04-01",
      "routing_instructions" => {
        "source" => "2442",
        "destination" => "+85512334667",
        "dial_string_format" => "sip/%{dial_string_path}/%{gateway_type}/%{gateway}/%{destination}@%{destination_host}/%{address}",
        "gateway_type" => "external",
        "gateway" => "my_gateway",
        "destination_host" => "somleng.io",
        "address" => "012345678",
        "dial_string_path" => "path/to/dial_string"
      }
    }.merge(options)
  end
end
