require 'spec_helper'

describe DrbEndpoint do
  describe "#initiate_outbound_call!(call_json)" do
    let(:sample_call_json) { "{\"to\":\"+85512334667\",\"from\":\"2442\",\"voice_url\":\"https://rapidpro.ngrok.com/handle/33/\",\"voice_method\":\"GET\",\"status_callback_url\":\"https://rapidpro.ngrok.com/handle/33/\",\"status_callback_method\":\"POST\",\"sid\":\"91171124-2da9-40df-b21f-2531c895ff83\",\"account_sid\":\"acf75d31-b951-41d0-bb36-e2c48739308a\",\"account_auth_token\":\"7b7cff7af0aa74286404902622605af8e2da186aea4f65a6774563db9a8c6670\",\"routing_instructions\":{\"source\":\"2442\",\"destination\":\"+85512334667\"}}" }

    let(:call_json) { sample_call_json }

    let(:call) { instance_double(Adhearsion::OutboundCall, :id => call_id) }
    let(:call_id) { "becf0231-3028-4e10-8f40-e77ec6c8fd6d" }
    let(:asserted_call_id) { call_id }

    let(:asserted_dial_string) { "+85512334667" }
    let(:asserted_caller_id) { "2442" }
    let(:asserted_call_controller) { CallController }
    let(:asserted_controller_metadata) do
      {
        :voice_request_url=>"https://rapidpro.ngrok.com/handle/33/",
        :voice_request_method=>"GET",
        :status_callback_url=>"https://rapidpro.ngrok.com/handle/33/",
        :status_callback_method=>"POST",
        :account_sid=>"acf75d31-b951-41d0-bb36-e2c48739308a",
        :auth_token=>"7b7cff7af0aa74286404902622605af8e2da186aea4f65a6774563db9a8c6670",
        :call_sid=>"91171124-2da9-40df-b21f-2531c895ff83"
      }
    end

    before do
      setup_scenario
    end

    def setup_scenario
      allow(Adhearsion::OutboundCall).to receive(:originate).and_return(call)
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

    context "by default" do
      it { assert_outbound_call! }
    end

    context "#routing_instructions" do
      let(:call_params) { { "routing_instructions" => routing_instructions } }
      let(:call_json) { JSON.parse(sample_call_json).merge(call_params).to_json }

      context "dial_string_format" do
        let(:routing_instructions) { { "dial_string_format" => "sip/gateways/%{gateway}/%{destination}@%{destination_host}", "gateway" => "my_gateway", "destination" => "85512345678", "destination_host" => "somleng.io"} }

        let(:asserted_dial_string) { "sip/gateways/my_gateway/85512345678@somleng.io" }

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
