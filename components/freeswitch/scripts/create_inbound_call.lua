freeswitch.consoleLog("info", "Creating inbound call")

local json = require "cjson"
local api = freeswitch.API()

local call_platform_host = os.getenv("FS_CALL_PLATFORM_HOST")

local payload = {
  to = session:getVariable("sip_h_X-Somleng-Callee-Identity"),
  from = session:getVariable("sip_h_X-Somleng-Caller-Identity"),
  external_id = session:getVariable("uuid"),
  host = session:getVariable("fs_host_ip"),
  source_ip = session:getVariable("sip_h_X-Src-Ip"),
  client_identifier = session:getVariable("sip_h_X-Somleng-Client-Identifier"),
  variables = {
    sip_from_host = session:getVariable("sip_from_host"),
    sip_to_host = session:getVariable("sip_to_host"),
    sip_network_ip = session:getVariable("sip_network_ip"),
    sip_via_host = session:getVariable("sip_via_host")
  }
}

local body = json.encode(payload)
local params = call_platform_host .. "/services/inbound_phone_calls" .. " post " .. body

local response = api:execute("curl", params)
local data = json.decode(response)

freeswitch.consoleLog("INFO", json.encode(data) .. "\n")
