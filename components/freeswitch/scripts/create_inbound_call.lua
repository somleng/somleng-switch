freeswitch.consoleLog("info", "Creating inbound call")

local json = require "cjson"
local api = freeswitch.API()

local response = api:execute("curl", "https://jsonplaceholder.typicode.com/todos/1")
local data = json.decode(response)


freeswitch.consoleLog("INFO", json.encode(data) .. "\n")
