class OutboundCall
  attr_reader :call_params

  def initialize(call_params)
    @call_params = call_params
  end

  def initiate
    dial_string = DialString.new(call_params)
    sip_headers = build_sip_headers(dial_string)
    call_properties = build_call_properties(sip_headers)

    Adhearsion::OutboundCall.originate(
      dial_string.to_s,
      from: dial_string.format_number(call_params.fetch("from")),
      controller: CallController,
      controller_metadata: {
        call_properties:
      },
      headers: build_call_headers(sip_headers)
    )
  end

  private

  def build_call_headers(sip_headers)
    return sip_headers.to_h unless CallPlatform.configuration.stub_responses

    sip_headers.to_h.merge(call_params.fetch("test_headers", {}))
  end

  def build_call_properties(sip_headers)
    CallProperties.new(
      voice_url: call_params.fetch("voice_url"),
      voice_method: call_params.fetch("voice_method"),
      twiml: call_params["twiml"],
      account_sid: call_params.fetch("account_sid"),
      auth_token: call_params.fetch("account_auth_token"),
      call_sid: call_params.fetch("sid"),
      direction: call_params.fetch("direction"),
      api_version: call_params.fetch("api_version"),
      from: call_params.fetch("from"),
      to: call_params.fetch("to"),
      default_tts_voice: call_params.fetch("default_tts_voice"),
      sip_headers:
    )
  end

  def build_sip_headers(dial_string)
    SIPHeaders.new(
      call_sid: call_params.fetch("sid"),
      account_sid: call_params.fetch("account_sid"),
      carrier_sid: call_params.fetch("carrier_sid"),
      call_direction: call_params.fetch("call_direction"),
      billing_enabled: call_params.dig("billing_parameters", "enabled"),
      billing_mode: call_params.dig("billing_parameters", "billing_mode"),
      billing_category: call_params.dig("billing_parameters", "category"),
      proxy_address: dial_string.proxy_address
    )
  end
end
