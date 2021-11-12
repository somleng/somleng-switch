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
    nat_supported = routing_instructions.fetch("nat_supported", true)
    Adhearsion::OutboundCall.originate(
      DialString.new(
        routing_instructions.fetch("dial_string"),
        nat_supported: nat_supported
      ).to_s,
      from: call_params.fetch("from"),
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
          sip_headers: sip_headers
        )
      },
      headers: sip_headers.to_h
    )
  end

  private

  def routing_instructions
    call_params.fetch("routing_instructions", {})
  end
end
