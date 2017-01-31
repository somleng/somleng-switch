require 'spec_helper'

describe DrbEndpoint do
  include EnvHelpers

  def set_dummy_encryption_key
    stub_env(:ahn_somleng_encryption_key => "shh-dont-tell")
  end

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
    let(:call_json_auth_token) { "sample-auth-token" }
    let(:call_json_account_sid) { "sample-call-sid" }

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

    def asserted_headers
      {
        "X-Adhearsion-Twilio-Status-Callback-Url" => asserted_status_callback_url,
        "X-Adhearsion-Twilio-Status-Callback-Method" => asserted_status_callback_method,
        "X-Adhearsion-Twilio-Call-Sid" => asserted_call_sid,
        "X-Adhearsion-Twilio-To" => asserted_adhearsion_twilio_to,
        "X-Adhearsion-Twilio-From" => asserted_adhearsion_twilio_from,
        "X-Adhearsion-Twilio-Direction" => asserted_call_direction,
        "X-Adhearsion-Twilio-Account-Sid" => asserted_account_sid
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
        :controller_metadata => asserted_controller_metadata,
        :headers => hash_including(asserted_headers)
      )
      expect(call).to receive(:register_event_handler).with(Adhearsion::Event::End)
    end

    def assert_outbound_call!
      setup_expectations
      expect(subject.initiate_outbound_call!(call_json)).to eq(asserted_call_id)
    end

    context "by default" do
      def asserted_headers
        super.merge("X-Adhearsion-Twilio-Auth-Token" => asserted_auth_token)
      end

      it { assert_outbound_call! }
    end

    context "encryption key is provided" do
      before do
        set_dummy_encryption_key
      end

      def asserted_headers
        super.merge(
          "X-Adhearsion-Twilio-Encrypted-Auth-Token" => anything,
          "X-Adhearsion-Twilio-Encrypted-Auth-Token-IV" => anything
        )
      end

      it { assert_outbound_call! }
    end

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
    let(:header_billsec) { "0" }
    let(:header_account_sid) { "987654321" }
    let(:header_answer_epoch) { "" }
    let(:header_encrypted_auth_token) { nil }
    let(:header_encrypted_auth_token_iv) { nil }

    let(:asserted_status_callback_url) { header_status_callback_url }
    let(:asserted_status_callback_method) { header_status_callback_method }
    let(:asserted_call_to) { header_adhearsion_twilio_to }
    let(:asserted_call_from) { header_adhearsion_twilio_from }
    let(:asserted_call_sid) { header_call_sid }
    let(:asserted_auth_token) { header_auth_token }
    let(:asserted_call_direction) { header_call_direction }
    let(:asserted_call_duration) { header_billsec }
    let(:asserted_sip_response_code) { header_sip_term_status }
    let(:asserted_account_sid) { header_account_sid }

    let(:asserted_notify_status_callback_url_options) {
      {
        "CallDuration" => asserted_call_duration,
        "SipResponseCode" => asserted_sip_response_code
      }
    }

    let(:asserted_notify_status_callback_url_args) {
      [
        asserted_notify_status_callback_url_status,
        asserted_notify_status_callback_url_options
      ].compact
    }

    let :stanza do
      <<-MESSAGE
<end xmlns="urn:xmpp:rayo:1">
  <timeout platform-code="18" />
  <!-- Signaling (e.g. SIP) Headers -->
  <header name="variable-sip_term_status" value="#{header_sip_term_status}" />
  <header name="variable-billsec" value="#{header_billsec}" />
  <header name="variable-answer_epoch" value="#{header_answer_epoch}" />
  <header name="X-Adhearsion-Twilio-Status-Callback-Url" value="#{header_status_callback_url}" />
  <header name="X-Adhearsion-Twilio-Status-Callback-Method" value="#{header_status_callback_method}" />
  <header name="X-Adhearsion-Twilio-To" value="#{header_adhearsion_twilio_to}" />
  <header name="X-Adhearsion-Twilio-From" value="#{header_adhearsion_twilio_from}" />
  <header name="X-Adhearsion-Twilio-Call-Sid" value="#{header_call_sid}" />
  <header name="X-Adhearsion-Twilio-Direction" value="#{header_call_direction}" />
  <header name="X-Adhearsion-Twilio-Account-Sid" value="#{header_account_sid}" />
  <header name="X-Adhearsion-Twilio-Auth-Token" value="#{header_auth_token}" />
  <header name="X-Adhearsion-Twilio-Encrypted-Auth-Token" value="#{header_encrypted_auth_token}" />
  <header name="X-Adhearsion-Twilio-Encrypted-Auth-Token-IV" value="#{header_encrypted_auth_token_iv}" />
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

    def trigger_event
      subject.send(:handle_event_end, event)
    end

    def assert_handle_event_end!
      expect(http_client).to receive(:notify_status_callback_url).with(*asserted_notify_status_callback_url_args)
      expect(http_client_class).to receive(:new).with(
        hash_including(
          :status_callback_url => asserted_status_callback_url,
          :status_callback_method => asserted_status_callback_method,
          :call_to => asserted_call_to,
          :call_from => asserted_call_from,
          :call_sid => asserted_call_sid,
          :account_sid => asserted_account_sid,
          :auth_token => asserted_auth_token,
          :call_direction => asserted_call_direction,
        )
      )
      trigger_event
    end

    before do
      setup_scenario
    end

    context "given the call is not_answered" do
      let(:header_sip_term_status) { "480" }
      let(:asserted_notify_status_callback_url_status) { :no_answer }
      it { assert_handle_event_end! }

      context "given the auth token is encrypted" do
        before do
          set_dummy_encryption_key
        end

        let(:header_encrypted_auth_token) { "3wCh/wuFmfl62z253vLTCBrpEig9IYD0Z77JrpHAMJ8=&#10;" }
        let(:header_encrypted_auth_token) { "3wCh/wuFmfl62z253vLTCBrpEig9IYD0Z77JrpHAMJ8=&#38;&#35;10&#59;" }
        let(:header_encrypted_auth_token_iv) { "xuNbWFfCbZUnMjgItwb8QA==&#38;&#35;10&#59;" }
        let(:header_auth_token) { "not-the-real-auth-token" }
        let(:asserted_auth_token) { "sample-auth-token" }
        it { assert_handle_event_end! }
      end
    end

    context "given the call is cancelled by originator" do
      let(:header_sip_term_status) { "487" }
      let(:asserted_notify_status_callback_url_status) { :no_answer }
      it { assert_handle_event_end! }
    end

    context "given the call is busy" do
      let(:header_sip_term_status) { "486" }
      let(:asserted_notify_status_callback_url_status) { :busy }
      it { assert_handle_event_end! }
    end

    context "given the number is wrong" do
      let(:header_sip_term_status) { "484" }
      let(:asserted_notify_status_callback_url_status) { :error }
      it { assert_handle_event_end! }
    end

    context "given the call is answered" do
      def assert_handle_event_end!
        expect(http_client).not_to receive(:notify_status_callback_url)
        trigger_event
      end

      context "as defined by answer-epoch" do
        let(:header_answer_epoch) { "1478050584" }
        let(:header_sip_term_status) { nil }
        it { assert_handle_event_end! }
      end

      context "as defined by sip_term_status" do
        let(:header_sip_term_status) { "200" }
        it { assert_handle_event_end! }
      end
    end
  end
end
