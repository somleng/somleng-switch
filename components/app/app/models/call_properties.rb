CallProperties = Struct.new(
  :voice_url,
  :voice_method,
  :twiml,
  :account_sid,
  :auth_token,
  :call_sid,
  :direction,
  :api_version,
  :to,
  :from,
  :sip_headers,
  :default_tts_voice_identifier,
  keyword_init: true
) do
  def inbound?
    direction == "inbound"
  end
end
