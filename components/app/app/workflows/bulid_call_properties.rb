class BuildCallProperties < ApplicationWorkflow
  attr_reader :call_params

  def initialize(call_params)
    super()
    @call_params = call_params
  end

  def call
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

  private

  def sip_headers
    @sip_headers ||= SIPHeaders.new(
      call_sid: call_params.fetch("sid"),
      account_sid: call_params.fetch("account_sid")
    )
  end
end
