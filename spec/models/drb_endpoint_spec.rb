require 'spec_helper'

describe DrbEndpoint do
  describe "#initiate_outbound_call!(call_json)" do
    let(:sample_call_json) { "{\"to\":\"+85512334667\",\"from\":\"2442\",\"voice_url\":\"https://rapidpro.ngrok.com/handle/33/\",\"voice_method\":\"GET\",\"status_callback_url\":\"https://rapidpro.ngrok.com/handle/33/\",\"status_callback_method\":\"POST\",\"sid\":\"91171124-2da9-40df-b21f-2531c895ff83\",\"account_sid\":\"acf75d31-b951-41d0-bb36-e2c48739308a\",\"account_auth_token\":\"7b7cff7af0aa74286404902622605af8e2da186aea4f65a6774563db9a8c6670\",\"routing_instructions\":{\"source\":\"2442\",\"destination\":\"+85512334667\"}}" }

    let(:call_json) { sample_call_json }
    let(:asserted_call_id) { call_id }
    let(:call) { instance_double(Adhearsion::OutboundCall, :id => call_id) }
    let(:call_id) { "becf0231-3028-4e10-8f40-e77ec6c8fd6d" }

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
        :call_sid=>"91171124-2da9-40df-b21f-2531c895ff83",
        :call_direction=>:outbound_api,
        :rest_api_enabled=>false
      }
    end

    before do
      setup_scenario
    end

    def setup_scenario
      allow(Adhearsion::OutboundCall).to receive(:originate).and_return(call)
      allow(call).to receive(:from).and_return(asserted_dial_string)
      allow(call).to receive(:to).and_return(asserted_caller_id)
      allow(call).to receive(:register_event_handler)
    end

    def setup_expectations
      expect(Adhearsion::OutboundCall).to receive(:originate).with(
        asserted_dial_string,
        :from => asserted_caller_id,
        :controller => CallController,
        :controller_metadata => asserted_controller_metadata
      )
      expect(call).to receive(:register_event_handler).with(Adhearsion::Event::Answered)
      expect(call).to receive(:register_event_handler).with(Adhearsion::Event::End)
    end

    def assert_outbound_call!
      setup_expectations
      expect(subject.initiate_outbound_call!(call_json)).to eq(asserted_call_id)
      if asserted_call_id
        expect(subject.outbound_call).to eq(call)
        expect(subject.call_to).to be_present
        expect(subject.call_from).to be_present
        expect(subject.outbound_call_sid).to be_present
      end
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

  describe "#handle_event_answered" do
    before do
      subject.send(:handle_event_answered, Adhearsion::Event::Answered.new)
    end

    it { expect(subject.send(:answered?)).to eq(true) }
  end

  describe "#handle_event_end" do
    let(:http_client_class) { Adhearsion::Twilio::HttpClient }
    let(:http_client) { instance_double(http_client_class) }

    let(:call_to) { "+85512334667" }
    let(:call_from) { "+85512334667" }
    let(:outbound_call_sid) { "abcdefghij" }
    let(:status_callback_url) { nil }
    let(:status_callback_method) { nil }
    let(:asserted_status_callback_url) { nil }
    let(:asserted_status_callback_method) { Adhearsion::Twilio::Configuration::DEFAULT_STATUS_CALLBACK_METHOD }

    def setup_scenario
      subject.call_to = call_to
      subject.call_from = call_from
      subject.outbound_call_sid = outbound_call_sid
      subject.status_callback_url = status_callback_url
      subject.status_callback_method = status_callback_method
      allow(http_client).to receive(:notify_status_callback_url)
      allow(http_client_class).to receive(:new).and_return(http_client)
    end

    def assert_handle_event_end!
      expect(http_client).to receive(:notify_status_callback_url).with(:no_answer)
      expect(http_client_class).to receive(:new).with(
        hash_including(
          :call_to => call_to,
          :call_from => call_from,
          :call_sid => outbound_call_sid,
          :status_callback_url => asserted_status_callback_url,
          :status_callback_method => asserted_status_callback_method
        )
      )
      subject.send(:handle_event_end, Adhearsion::Event::End.new)
    end

    before do
      setup_scenario
    end

    context "given the call is not answered" do
      let(:asserted_status) { :no_answer }
      it { assert_handle_event_end! }
    end

    context "given the call is answered" do
      def setup_scenario
        subject.answered = true
        super
      end

      it { expect(http_client).not_to receive(:notify_status_callback_url) }
    end
  end
end
