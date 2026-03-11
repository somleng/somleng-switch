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

    CallProperties.new(
      voice_url: call.variables.fetch("variable_somleng_voice_url"),
      voice_method: call.variables.fetch("variable_somleng_voice_method"),
      twiml: call.variables.fetch("variable_somleng_twiml"),
      account_sid: call.variables.fetch("variable_somleng_account_sid"),
      auth_token: call.variables.fetch("variable_somleng_auth_token"),
      call_sid: call.variables.fetch("variable_somleng_call_sid"),
      direction: call.variables.fetch("variable_somleng_direction"),
      api_version: call.variables.fetch("variable_somleng_api_version"),
      to: call.variables.fetch("variable_somleng_to"),
      from: call.variables.fetch("variable_somleng_from"),
      default_tts_voice: call.variables.fetch("variable_somleng_default_tts_voice"),
      sip_headers: SIPHeaders.new(
        call_sid: call.variables.fetch("variable_somleng_call_sid"),
        account_sid: call.variables.fetch("variable_somleng_account_sid"),
        carrier_sid: call.variables.fetch("variable_somleng_carrier_sid"),
        call_direction: call.variables.fetch("variable_somleng_call_direction"),
        billing_enabled: call.variables.fetch("variable_somleng_billing_enabled"),
        billing_mode: call.variables.fetch("variable_somleng_billing_mode"),
        billing_category: call.variables.fetch("variable_somleng_billing_category"),
        proxy_address: nil
      )
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
