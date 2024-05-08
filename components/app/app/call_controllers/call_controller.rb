class CallController < Adhearsion::CallController
  include Skylight::Helpers

  attr_reader :call_properties

  before :register_event_handlers

  instrument_method
  def run
    @call_properties = build_call_properties

    twiml = prepare_twiml(call_properties)
    execute_twiml(twiml)
  end

  def redirect(**options)
    twiml = options.fetch(:twiml) do
      request_twiml(
        options.fetch(:url),
        options[:http_method],
        options.fetch(:params, {}).reverse_merge("CallStatus" => "in-progress")
      )
    end

    execute_twiml(twiml)
  end

  def call_platform_client
    if CallPlatform.configuration.stub_responses
      CallPlatform::FakeClient.new
    else
      CallPlatform::Client.new
    end
  end

  private

  def register_event_handlers
    NotifyCallEvent.subscribe_events(call, client: call_platform_client)
  end

  def build_call_properties
    return metadata[:call_properties] if metadata[:call_properties].present?

    response = call_platform_client.create_call(
      to: call.variables.fetch("variable_sip_h_x_somleng_callee_identity"),
      from: call.variables.fetch("variable_sip_h_x_somleng_caller_identity"),
      external_id: call.id,
      source_ip: call.variables["variable_sip_h_x_src_ip"] || call.variables["variable_sip_via_host"],
      client_identifier: call.variables["variable_sip_h_x_somleng_client_identifier"],
      variables: {
        sip_from_host: call.variables["variable_sip_from_host"],
        sip_to_host: call.variables["variable_sip_to_host"],
        sip_network_ip: call.variables["variable_sip_network_ip"],
        sip_via_host: call.variables["variable_sip_via_host"]
      }
    )
    CallProperties.new(
      voice_url: response.voice_url,
      voice_method: response.voice_method,
      twiml: response.twiml,
      account_sid: response.account_sid,
      auth_token: response.auth_token,
      call_sid: response.call_sid,
      direction: response.direction,
      api_version: response.api_version,
      to: response.to,
      from: response.from,
      default_tts_voice: response.default_tts_voice,
      sip_headers: SIPHeaders.new(call_sid: response.call_sid, account_sid: response.account_sid)
    )
  end

  def twiml_endpoint
    @twiml_endpoint ||= TwiMLEndpoint.new(auth_token: call_properties.auth_token)
  end

  def prepare_twiml(call_properties)
    return call_properties.twiml if call_properties.voice_url.blank?

    request_twiml(
      call_properties.voice_url,
      call_properties.voice_method,
      "CallStatus" => "ringing"
    )
  end

  def request_twiml(url, http_method, params)
    request_params = {
      "Caller" => call_properties.from,
      "Called" => call_properties.to,
      "From" => call_properties.from,
      "To" => call_properties.to,
      "CallSid" => call_properties.call_sid,
      "Direction" => call_properties.direction,
      "AccountSid" => call_properties.account_sid,
      "ApiVersion" => call_properties.api_version
    }.merge(params)

    twiml_endpoint.request(
      url,
      http_method,
      request_params
    )
  end

  def execute_twiml(twiml)
    ExecuteTwiML.call(
      context: self,
      twiml:,
      call_properties:,
      phone_call: call,
      call_platform_client:,
      logger:,
      stub_call_platform_responses: CallPlatform.configuration.stub_responses
    )
  end

  def output_formatter
    SSMLFormatter.new
  end
end
