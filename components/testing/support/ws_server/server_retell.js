var http = require("http");
var HttpDispatcher = require("httpdispatcher");
var assert = require('assert');

const argv = require("minimist")(process.argv.slice(2));
const port = argv.port && parseInt(argv.port) ? parseInt(argv.port) : 8888;
const api_key = argv.api_key  ? argv.api_key : null;
const agent_id = argv.agent_id  ? argv.agent_id : null;

assert.ok(api_key, 'Retell api key not provided')
assert.ok(agent_id, 'Retell agent id not provided')

var dispatcher = new HttpDispatcher();
var wsserver = http.createServer(handleRequest);
function handleRequest(request, response) {
  try {
    dispatcher.dispatch(request, response);
  } catch (err) {
    console.error(err);
  }
}

dispatcher.onPost("/connect", async function (req, res) {
  console.log("POST TwiML");
  const call_id = await registerCall()
  res.write(makeTwilioConnect(call_id)); 
  res.end();
});

async function registerCall() {
  const response = await fetch("https://api.retellai.com/register-call", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${api_key}`,
      "Content-type": "application/json"
    },

    body: JSON.stringify({
      agent_id: agent_id,
      audio_websocket_protocol: "twilio",
      audio_encoding: "mulaw",
      sample_rate: 8000
    })
  })

  const json = await response.json();
  return json.call_id;
}

function makeTwilioConnect(call_id) {
  const wsUrl = `wss://api.retellai.com/audio-websocket/${call_id}`; 
  console.log(`makeTwilioConnect socker url: ${wsUrl}`)
  return `<?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Connect>
      <Stream url="${wsUrl}"></Stream>
    </Connect>
  </Response>`
}

wsserver.listen(http_port, function () {
  console.log("Server listening on: http://localhost:%s", http_port);
});
