class CallController < Adhearsion::CallController
  before :register_event_handlers

  def run
    @call_properties = build_call_properties

    twiml = request_twiml(
      call_properties.voice_url,
      call_properties.voice_method,
      "CallStatus" => "ringing"
    )

    execute_twiml(twiml)
  end

  def redirect(url = nil, http_method = nil, params = {})
    twiml = request_twiml(
      url,
      http_method,
      params.reverse_merge("CallStatus" => "in-progress")
    )

    execute_twiml(twiml)
  end

  private

  attr_reader :call_properties

  def call_platform_client
    CallPlatform::Client.new
  end

  def register_event_handlers
    NotifyCallEvent.subscribe_events(call)
  end

  def build_call_properties
    return metadata[:call_properties] if metadata[:call_properties].present?

    response = call_platform_client.create_call(
      to: normalized_call.to,
      from: normalized_call.from,
      external_id: call.id,
      variables: {
        sip_from_host: call.variables["variable_sip_from_host"],
        sip_to_host: call.variables["variable_sip_to_host"],
        sip_network_ip: call.variables["variable_sip_network_ip"]
      }
    )
    CallProperties.new(
      voice_url: response.voice_url,
      voice_method: response.voice_method,
      account_sid: response.account_sid,
      auth_token: response.auth_token,
      call_sid: response.call_sid,
      direction: response.direction,
      api_version: response.api_version,
      to: response.to,
      from: response.from
    )
  end

  def normalized_call
    @normalized_call ||= NormalizedCall.new(call)
  end

  def twiml_endpoint
    @twiml_endpoint ||= TwiMLEndpoint.new(auth_token: call_properties.auth_token)
  end

  def request_twiml(url, http_method, params)
    request_params = {
      "From" => format_number(call_properties.from),
      "To" => format_number(call_properties.to),
      "CallSid" => call_properties.call_sid,
      "Direction" => call_properties.direction,
      "AccountSid" => call_properties.account_sid,
      "ApiVersion" => call_properties.api_version
    }.merge(params)

    twiml_endpoint.request(
      url,
      http_method,
      request_params,
      logger: logger
    )
  end

  def execute_twiml(twiml)
    ExecuteTwiML.call(context: self, twiml: twiml)
  end

  def format_number(number)
    Phony.plausible?(number) ? "+#{number}" : number
  end
end
