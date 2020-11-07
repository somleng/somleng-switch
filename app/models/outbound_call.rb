class OutboundCall
  attr_reader :call_params

  def initialize(call_params)
    @call_params = call_params
  end

  def initiate
    Adhearsion::OutboundCall.originate(
      dial_string,
      from: caller_id,
      controller: CallController,
      controller_metadata: {
        voice_request_url: call_params.fetch("voice_url"),
        voice_request_method: call_params.fetch("voice_method"),
        account_sid: call_params.fetch("account_sid"),
        auth_token: call_params.fetch("account_auth_token"),
        call_sid: call_params.fetch("sid"),
        direction: call_params.fetch("direction"),
        api_version: call_params.fetch("api_version"),
        rest_api_enabled: false
      }
    )
  end

  private

  def routing_instructions
    call_params.fetch("routing_instructions", {})
  end

  def caller_id
    call_params.fetch("from")
  end

  def destination
    call_params.fetch("to")
  end

  def dial_string
    ["sofia/external", routing_instructions.fetch("dial_string")].join("/")
  end
end
