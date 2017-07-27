require 'spec_helper'

describe DrbEndpoint do
  include EnvHelpers

  let(:dummy_encryption_key) { "shh-dont-tell" }

  def env
    {}
  end

  def setup_scenario
    stub_env(env)
  end

  before do
    setup_scenario
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

    def setup_scenario
      super
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
      expect(call).to receive(:register_event_handler).with(Adhearsion::Event::Ringing)
      expect(call).to receive(:register_event_handler).with(Adhearsion::Event::Answered)
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
      def env
        super.merge(
          :ahn_somleng_encryption_key => dummy_encryption_key
        )
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

  describe "event handlers" do
    let(:stanza) { build_rayo_event_stanza }
    let(:event) { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root, '9f00061', '1') }
    let(:header_call_sid) { "abcdefghij" }
    let(:asserted_call_sid) { header_call_sid }
    let(:basic_auth_credentials) { "user:secret" }
    let(:phone_call_events_url) {
      "https://#{basic_auth_credentials}@somleng.example.com/api/admin/phone_calls/:phone_call_id/events/:event_type"
    }
    let(:assert_notify_event) { true }

    let(:phone_call_event_url) {
      interpolate_phone_call_events_url(
        :phone_call_id => asserted_call_sid,
        :event_type => asserted_event_type
      )
    }

    def trigger_event!
      subject.send(event_handler, event)
    end

    def parse_stanza(xml)
      Nokogiri::XML.parse(xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS)
    end

    def interpolate_phone_call_events_url(interpolations = {})
      event_url = phone_call_events_url.dup
      interpolations.each do |interpolation, value|
        event_url.sub!(":#{interpolation}", value.to_s)
      end
      event_url.sub!("#{basic_auth_credentials}@", "")
      event_url
    end

    def rayo_event_stanza_headers
      {
        "X-Adhearsion-Twilio-Call-Sid" => header_call_sid
      }
    end

    def rayo_event_stanza_children
      rayo_event_stanza_children = []
      rayo_event_stanza_headers.each do |key, value|
        rayo_event_stanza_children << {
          :element_type => :header,
          :element_attributes => [
            {
              :name => key,
              :value => value
            }
          ]
        }
      end
      rayo_event_stanza_children
    end

    def build_rayo_event_stanza
      children_xml = []
      rayo_event_stanza_children.each do |child|
        attributes = [child[:element_type]]
        child[:element_attributes].each do |element_attribute|
          element_attribute.each do |key, value|
            attributes << "#{key}=\"#{value}\""
          end
        end

        children_xml << "<#{attributes.join(' ')} />"
      end

      <<-MESSAGE
        <#{rayo_event_type} xmlns="urn:xmpp:rayo:1">
          #{children_xml.join("\n")}
        </#{rayo_event_type}>
      MESSAGE
    end

    def assert_notify_event!
      expect(WebMock).to have_requested(
        :post, phone_call_event_url
      ).with(
        :headers => {
          'Authorization' => "Basic #{Base64.strict_encode64(basic_auth_credentials).chomp}"
        }
      )
    end

    def assert_event!
      trigger_event!
      assert_notify_event! if assert_notify_event
    end

    def env
      super.merge(
        :ahn_somleng_phone_call_events_url => phone_call_events_url
      )
    end

    def setup_scenario
      super
      stub_request(:post, phone_call_event_url) if phone_call_events_url
    end

    describe "#handle_event_ringing(event)" do
      let(:event_handler) { :handle_event_ringing }
      let(:asserted_event_type) { :ringing }
      let(:rayo_event_type) { :ringing }
      it { assert_event! }
    end

    describe "#handle_event_answered(event)" do
      let(:event_handler) { :handle_event_answered }
      let(:asserted_event_type) { :answered }
      let(:rayo_event_type) { :answered }
      it { assert_event! }
    end

    describe "#handle_event_end(event)" do
      let(:event_handler) { :handle_event_end }
      let(:asserted_event_type) { :completed }
      let(:rayo_event_type) { :end }
      let(:notify_status_callback_url) { true }

      let(:http_client_class) { Adhearsion::Twilio::HttpClient }
      let(:http_client) { instance_double(http_client_class) }

      let(:header_sip_term_status) { "200" }
      let(:header_status_callback_url) { "https://status-callback.com/status_callback.xml" }
      let(:header_status_callback_method) { "POST" }
      let(:header_adhearsion_twilio_to) { "+85512345678" }
      let(:header_adhearsion_twilio_from) { "+2442" }
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

      def rayo_event_stanza_headers
        super.merge(
          "variable-sip_term_status" => header_sip_term_status,
          "variable-billsec" => header_billsec,
          "variable-answer_epoch" => header_answer_epoch,
          "X-Adhearsion-Twilio-Status-Callback-Url" => header_status_callback_url,
          "X-Adhearsion-Twilio-Status-Callback-Method" => header_status_callback_method,
          "X-Adhearsion-Twilio-To" => header_adhearsion_twilio_to,
          "X-Adhearsion-Twilio-From" => header_adhearsion_twilio_from,
          "X-Adhearsion-Twilio-Direction" => header_call_direction,
          "X-Adhearsion-Twilio-Account-Sid" => header_account_sid,
          "X-Adhearsion-Twilio-Auth-Token" => header_auth_token,
          "X-Adhearsion-Twilio-Encrypted-Auth-Token" => header_encrypted_auth_token,
          "X-Adhearsion-Twilio-Encrypted-Auth-Token-IV" => header_encrypted_auth_token_iv,
        )
      end

      def rayo_event_stanza_children
        super << {
          :element_type => :timeout,
          :element_attributes => [
            {
              "platform-code" => "18"
            }
          ]
        }
      end

      def setup_scenario
        super
        allow(http_client_class).to receive(:new).and_return(http_client)
      end

      def assert_event!
        if notify_status_callback_url
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
        else
          expect(http_client).not_to receive(:notify_status_callback_url)
        end

        super
      end

      context "given the call is not_answered" do
        let(:header_sip_term_status) { "480" }
        let(:asserted_notify_status_callback_url_status) { :no_answer }
        it { assert_event! }

        context "given the auth token is encrypted" do
          def env
            super.merge(
              :ahn_somleng_encryption_key => dummy_encryption_key
            )
          end

          let(:header_encrypted_auth_token) { "3wCh/wuFmfl62z253vLTCBrpEig9IYD0Z77JrpHAMJ8=&#10;" }
          let(:header_encrypted_auth_token) { "3wCh/wuFmfl62z253vLTCBrpEig9IYD0Z77JrpHAMJ8=&#38;&#35;10&#59;" }
          let(:header_encrypted_auth_token_iv) { "xuNbWFfCbZUnMjgItwb8QA==&#38;&#35;10&#59;" }
          let(:header_auth_token) { "not-the-real-auth-token" }
          let(:asserted_auth_token) { "sample-auth-token" }

          it { assert_event! }
        end
      end

      context "given the call is cancelled by originator" do
        let(:header_sip_term_status) { "487" }
        let(:asserted_notify_status_callback_url_status) { :no_answer }
        it { assert_event! }
      end

      context "given the call is busy" do
        let(:header_sip_term_status) { "486" }
        let(:asserted_notify_status_callback_url_status) { :busy }
        it { assert_event! }
      end

      context "given the number is wrong" do
        let(:header_sip_term_status) { "484" }
        let(:asserted_notify_status_callback_url_status) { :error }
        it { assert_event! }
      end

      context "given a '603'" do
        # https://en.wikipedia.org/wiki/List_of_SIP_response_codes#6xx.E2.80.94Global_Failure_Responses
        let(:header_sip_term_status) { "603" }
        let(:asserted_notify_status_callback_url_status) { :no_answer }
        it { assert_event! }
      end

      context "given the call is answered" do
        let(:notify_status_callback_url) { false }

        context "as defined by answer-epoch" do
          let(:header_answer_epoch) { "1478050584" }
          let(:header_sip_term_status) { nil }
          it { assert_event! }
        end

        context "as defined by sip_term_status" do
          let(:header_sip_term_status) { "200" }
          it { assert_event! }
        end
      end
    end
  end
end
