freeswitch.consoleLog("DEBUG", "Creating inbound call")

local json = require "cjson"
local mime = require("mime")
local api = freeswitch.API()

local function safe_string(v)
  if v == nil or v == json.null then
    return ""
  end
  return tostring(v)
end

local call_platform_host = os.getenv("FS_CALL_PLATFORM_HOST")
local call_platform_username = os.getenv("FS_CALL_PLATFORM_USERNAME")
local call_platform_password = os.getenv("FS_CALL_PLATFORM_PASSWORD")
local region = os.getenv("FS_REGION")

local payload = {
  to = session:getVariable("sip_h_X-Somleng-Callee-Identity"),
  from = session:getVariable("sip_h_X-Somleng-Caller-Identity"),
  external_id = session:getVariable("uuid"),
  host = session:getVariable("sip_network_ip"),
  source_ip = session:getVariable("sip_h_X-Src-Ip"),
  region = region,
  client_identifier = session:getVariable("sip_h_X-Somleng-Client-Identifier"),
  variables = {
    sip_from_host = session:getVariable("sip_from_host"),
    sip_to_host = session:getVariable("sip_to_host"),
    sip_network_ip = session:getVariable("sip_network_ip"),
    sip_via_host = session:getVariable("sip_via_host")
  }
}


local credentials = mime.b64(call_platform_username .. ":" .. call_platform_password)
local headers = "append_headers 'Authorization: Basic " .. credentials .. "' append_headers 'Accept: application/json' append_headers 'Content-Type: application/json'"

local body = json.encode(payload)
local params = call_platform_host .. "/inbound_phone_calls " .. headers .. " post " .. body .. " json"

local raw_response = api:execute("curl", params)

freeswitch.consoleLog("DEBUG", raw_response .. "\n")
local response = json.decode(raw_response)

if not string.match(response.status_code, "^2") then
  session:execute("respond", "403 Forbidden")
  session:execute("hangup")
  return
end

local data = json.decode(response.body)

session:setVariable("somleng_voice_url", safe_string(data.voice_url))
session:setVariable("somleng_voice_method", safe_string(data.voice_method))
session:setVariable("somleng_twiml", safe_string(data.twiml))
session:setVariable("somleng_account_sid", safe_string(data.account_sid))
session:setVariable("somleng_carrier_sid", safe_string(data.carrier_sid))
session:setVariable("somleng_call_sid", safe_string(data.sid))
session:setVariable("somleng_call_direction", safe_string(data.call_direction))
session:setVariable("somleng_account_auth_token", safe_string(data.account_auth_token))
session:setVariable("somleng_direction", safe_string(data.direction))
session:setVariable("somleng_api_version", safe_string(data.api_version))
session:setVariable("somleng_default_tts_voice", safe_string(data.default_tts_voice))
session:setVariable("somleng_from", safe_string(data.from))
session:setVariable("somleng_to", safe_string(data.to))
session:setVariable("somleng_billing_enabled", safe_string(data.billing_parameters.enabled))
session:setVariable("somleng_billing_mode", safe_string(data.billing_parameters.billing_mode))
session:setVariable("somleng_billing_category", safe_string(data.billing_parameters.category))

if data.billing_parameters.enabled then
  session:setVariable("cgr_tenant", data.carrier_sid)
  session:setVariable("cgr_account", data.account_sid)
  session:setVariable("cgr_category", data.billing_parameters.category)
  session:setVariable("cgr_reqtype", "*" .. data.billing_parameters.billing_mode)

  session:execute("park")
else
  session:setVariable("cgr_reqtype", "*none")
  session:execute("rayo")
end
