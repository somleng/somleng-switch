require 'spec_helper'

describe DrbEndpoint do
  def setup_scenario
  end

  before do
    setup_scenario
  end

  describe "#initiate_outbound_call!(call_json)" do
    let(:sample_call_json) { "{\"to\":\"#{call_json_to}\",\"from\":\"2442\",\"voice_url\":\"#{call_json_voice_url}\",\"voice_method\":\"#{call_json_voice_method}\",\"status_callback_url\":\"#{call_json_status_callback_url}\",\"status_callback_method\":\"#{call_json_status_callback_method}\",\"sid\":\"#{call_json_call_sid}\",\"account_sid\":\"#{call_json_account_sid}\",\"account_auth_token\":\"#{call_json_auth_token}\",\"direction\":\"#{call_json_direction}\",\"api_version\":\"#{call_json_api_version}\",\"routing_instructions\":{\"source\":\"2442\",\"destination\":\"+85512334667\"}}" }

    let(:call_json) { sample_call_json }
    let(:asserted_call_id) { call_id }
    let(:call) { instance_double(Adhearsion::OutboundCall, :id => call_id) }
    let(:call_id) { "becf0231-3028-4e10-8f40-e77ec6c8fd6d" }

    let(:asserted_dial_string) { "+85512334667" }
    let(:asserted_caller_id) { "2442" }
    let(:asserted_call_controller) { CallController }

    let(:call_json_voice_url) { "https://rapidpro.ngrok.com/handle/33/" }
    let(:call_json_voice_method) { "GET" }
    let(:call_json_status_callback_url) { "https://rapidpro.ngrok.com/handle/33/" }
    let(:call_json_status_callback_method) { "POST" }
    let(:call_json_to) { "+85512334667" }
    let(:call_json_call_sid) { "91171124-2da9-40df-b21f-2531c895ff83" }
    let(:call_json_auth_token) { "sample-auth-token" }
    let(:call_json_account_sid) { "sample-call-sid" }
    let(:call_json_direction) { "outbound-api" }
    let(:call_json_api_version) { "2010-04-01" }

    let(:asserted_voice_request_url) { call_json_voice_url }
    let(:asserted_voice_request_method) { call_json_voice_method }
    let(:asserted_call_sid) { call_json_call_sid }
    let(:asserted_adhearsion_twilio_to) { call_json_to }
    let(:asserted_adhearsion_twilio_from) { "+2442" }
    let(:asserted_auth_token) { call_json_auth_token }
    let(:asserted_account_sid) { call_json_account_sid }
    let(:asserted_rest_api_enabled) { false }
    let(:asserted_direction) { call_json_direction }
    let(:asserted_api_version) { call_json_api_version }

    let(:asserted_controller_metadata) do
      {
        :voice_request_url => asserted_voice_request_url,
        :voice_request_method => asserted_voice_request_method,
        :account_sid => asserted_account_sid,
        :auth_token => asserted_auth_token,
        :call_sid => asserted_call_sid,
        :adhearsion_twilio_to => asserted_adhearsion_twilio_to,
        :adhearsion_twilio_from => asserted_adhearsion_twilio_from,
        :direction => asserted_direction,
        :api_version => asserted_api_version,
        :rest_api_enabled => asserted_rest_api_enabled
      }
    end

    def setup_scenario
      super
      allow(Adhearsion::OutboundCall).to receive(:originate).and_return(call)
      allow(call).to receive(:from).and_return(asserted_dial_string)
      allow(call).to receive(:to).and_return(asserted_caller_id)
    end

    def setup_expectations
      expect(Adhearsion::OutboundCall).to receive(:originate).with(
        asserted_dial_string,
        :from => asserted_caller_id,
        :controller => CallController,
        :controller_metadata => asserted_controller_metadata
      )
    end

    def assert_outbound_call!
      setup_expectations
      expect(subject.initiate_outbound_call!(call_json)).to eq(asserted_call_id)
    end

    it { assert_outbound_call! }

    context "#routing_instructions" do
      let(:call_params) { { "routing_instructions" => routing_instructions } }
      let(:call_json) { JSON.parse(sample_call_json).merge(call_params).to_json }

      context "dial_string_format" do
        let(:routing_instructions) { { "dial_string_format" => "sip/%{dial_string_path}/%{gateway_type}/%{gateway}/%{destination}@%{destination_host}/%{address}", "gateway_type" => "external", "gateway" => "my_gateway", "destination" => "85512345678", "destination_host" => "somleng.io", "address" => "012345678", "dial_string_path" => "path/to/dial_string"} }

        let(:asserted_dial_string) { "sip/path/to/dial_string/external/my_gateway/85512345678@somleng.io/012345678" }
        let(:asserted_adhearsion_twilio_to) { "+85512345678" }

        it { assert_outbound_call! }
      end

      context "disable_originate" do
        let(:routing_instructions) { { "disable_originate" => disable_originate } }
        let(:disable_originate) { "1" }
        let(:asserted_call_id) { nil }

        def setup_expectations
          expect(Adhearsion::OutboundCall).not_to receive(:originate)
        end

        it { assert_outbound_call! }
      end
    end
  end
end
