class OutboundCall
  attr_reader :call_params

  def initialize(call_params)
    @call_params = call_params
  end

  def initiate
    sip_headers = SIPHeaders.new(
      call_sid: call_params.fetch("sid"),
      account_sid: call_params.fetch("account_sid")
    )

    dial_string = DialString.new(call_params.fetch("routing_parameters"))

    Adhearsion::OutboundCall.originate(
      dial_string.to_s,
      from: dial_string.format_number(call_params.fetch("from")),
      controller: CallController,
      controller_metadata: {
        call_properties: CallProperties.new(
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
          default_tts_voice_identifier: call_params.fetch("default_tts_voice_identifier"),
          sip_headers:
        )
      },
      headers: build_call_headers(sip_headers)
    )
  end

  private

  def build_call_headers(sip_headers)
    return sip_headers.to_h unless CallPlatform.configuration.stub_responses

    sip_headers.to_h.merge(call_params.fetch("test_headers", {}))
  end
end
