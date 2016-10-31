require 'spec_helper'

describe DrbEndpoint do
  describe "#initiate_outbound_call!(call_json)" do
    let(:sample_call_json) { "{\"to\":\"#{call_json_to}\",\"from\":\"2442\",\"voice_url\":\"#{call_json_voice_url}\",\"voice_method\":\"#{call_json_voice_method}\",\"status_callback_url\":\"#{call_json_status_callback_url}\",\"status_callback_method\":\"#{call_json_status_callback_method}\",\"sid\":\"#{call_json_call_sid}\",\"account_sid\":\"#{call_json_account_sid}\",\"account_auth_token\":\"#{call_json_auth_token}\",\"routing_instructions\":{\"source\":\"2442\",\"destination\":\"+85512334667\"}}" }

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
    let(:call_json_auth_token) { "7b7cff7af0aa74286404902622605af8e2da186aea4f65a6774563db9a8c6670" }
    let(:call_json_account_sid) { "acf75d31-b951-41d0-bb36-e2c48739308a" }

    let(:asserted_voice_request_url) { call_json_voice_url }
    let(:asserted_voice_request_method) { call_json_voice_method }
    let(:asserted_status_callback_url) { call_json_status_callback_url }
    let(:asserted_status_callback_method) { call_json_status_callback_method }
    let(:asserted_call_sid) { call_json_call_sid }
    let(:asserted_adhearsion_twilio_to) { call_json_to }
    let(:asserted_adhearsion_twilio_from) { "+2442" }
    let(:asserted_call_direction) { "outbound_api" }
    let(:asserted_auth_token) { call_json_auth_token }
    let(:asserted_account_sid) { call_json_account_sid }
    let(:asserted_rest_api_enabled) { false }

    let(:asserted_controller_metadata) do
      {
        :voice_request_url => asserted_voice_request_url,
        :voice_request_method => asserted_voice_request_method,
        :status_callback_url => asserted_status_callback_url,
        :status_callback_method => asserted_status_callback_method,
        :account_sid => asserted_account_sid,
        :auth_token => asserted_auth_token,
        :call_sid => asserted_call_sid,
        :call_direction => asserted_call_direction,
        :adhearsion_twilio_to => asserted_adhearsion_twilio_to,
        :adhearsion_twilio_from => asserted_adhearsion_twilio_from,
        :rest_api_enabled => asserted_rest_api_enabled
      }
    end

    let(:asserted_headers) {
      {
        "X-Adhearsion-Twilio-Status-Callback-Url" => asserted_status_callback_url,
        "X-Adhearsion-Twilio-Status-Callback-Method" => asserted_status_callback_method,
        "X-Adhearsion-Twilio-Call-Sid" => asserted_call_sid,
        "X-Adhearsion-Twilio-To" => asserted_adhearsion_twilio_to,
        "X-Adhearsion-Twilio-From" => asserted_adhearsion_twilio_from,
        "X-Adhearsion-Twilio-Direction" => asserted_call_direction,
        "X-Adhearsion-Twilio-Auth-Token" => asserted_auth_token,
      }
    }

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
        :controller_metadata => asserted_controller_metadata,
        :headers => asserted_headers
      )
      expect(call).to receive(:register_event_handler).with(Adhearsion::Event::End)
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

  describe "#handle_event_end(event)" do
    let(:http_client_class) { Adhearsion::Twilio::HttpClient }
    let(:http_client) { instance_double(http_client_class) }

    let(:header_sip_term_status) { "200" }
    let(:header_status_callback_url) { "https://status-callback.com/status_callback.xml" }
    let(:header_status_callback_method) { "POST" }
    let(:header_adhearsion_twilio_to) { "+85512345678" }
    let(:header_adhearsion_twilio_from) { "+2442" }
    let(:header_call_sid) { "abcdefghij" }
    let(:header_call_direction) { "outbound_api" }
    let(:header_auth_token) { "12345678" }

    let(:asserted_status_callback_url) { header_status_callback_url }
    let(:asserted_status_callback_method) { header_status_callback_method }
    let(:asserted_call_to) { header_adhearsion_twilio_to }
    let(:asserted_call_from) { header_adhearsion_twilio_from }
    let(:asserted_call_sid) { header_call_sid }
    let(:asserted_auth_token) { header_auth_token }
    let(:asserted_call_direction) { header_call_direction }

    let :stanza do
      <<-MESSAGE
<end xmlns="urn:xmpp:rayo:1">
  <timeout platform-code="18" />
  <!-- Signaling (e.g. SIP) Headers -->
  <header name="variable-sip_term_status" value="#{header_sip_term_status}" />
  <header name="X-Adhearsion-Twilio-Status-Callback-Url" value="#{header_status_callback_url}" />
  <header name="X-Adhearsion-Twilio-Status-Callback-Method" value="#{header_status_callback_method}" />
  <header name="X-Adhearsion-Twilio-To" value="#{header_adhearsion_twilio_to}" />
  <header name="X-Adhearsion-Twilio-From" value="#{header_adhearsion_twilio_from}" />
  <header name="X-Adhearsion-Twilio-Call-Sid" value="#{header_call_sid}" />
  <header name="X-Adhearsion-Twilio-Direction" value="#{header_call_direction}" />
  <header name="X-Adhearsion-Twilio-Auth-Token" value="#{header_auth_token}" />
</end>
      MESSAGE
    end

    def parse_stanza(xml)
      Nokogiri::XML.parse(xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS)
    end

    let(:event) { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root, '9f00061', '1') }

    def setup_scenario
      allow(http_client_class).to receive(:new).and_return(http_client)
    end

    def assert_handle_event_end!
      expect(http_client).to receive(:notify_status_callback_url).with(:no_answer)
      expect(http_client_class).to receive(:new).with(
        hash_including(
          :status_callback_url => asserted_status_callback_url,
          :status_callback_method => asserted_status_callback_method,
          :call_to => asserted_call_to,
          :call_from => asserted_call_from,
          :call_sid => asserted_call_sid,
          :auth_token => asserted_auth_token,
          :call_direction => asserted_call_direction
        )
      )
      subject.send(:handle_event_end, event)
    end

    before do
      setup_scenario
    end

    context "given the call is not answered" do
      let(:header_sip_term_status) { "486" }
      it { assert_handle_event_end! }
    end

    context "given the call is answered" do
      let(:header_sip_term_status) { "200" }
      it { expect(http_client).not_to receive(:notify_status_callback_url) }
    end
  end
end
