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
  keyword_init: true
)
