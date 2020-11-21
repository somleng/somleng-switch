CallProperties = Struct.new(
  :voice_request_url,
  :voice_request_method,
  :account_sid,
  :auth_token,
  :call_sid,
  :direction,
  :api_version,
  keyword_init: true
)
