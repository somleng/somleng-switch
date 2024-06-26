// Usage:
// Obtain Retell API key and Agent ID from https://www.retellai.com/
// Obtain your Somleng credentials from https://app.somleng.org
// $ node retell_server.js --api_key <retell-api-key> --agent_id <retell-agent-id> --port 3000
// $ ngrok http 3000
// $ curl -X "POST" "https://api.somleng.org/2010-04-01/Accounts/<AccountSID>/Calls.json" \
//        -H 'Content-Type: application/x-www-form-urlencoded; charset=utf-8' \
//        -u '<AccountSID>:<AuthToken>' \
//        --data-urlencode "Url=<ngrok-url>" \
//        --data-urlencode "To=<destination-number>" \
//        --data-urlencode "From=<from-number>"

var http = require("http");
var HttpDispatcher = require("httpdispatcher");
var assert = require("assert");

const argv = require("minimist")(process.argv.slice(2));
const httpPort = argv.port && parseInt(argv.port) ? parseInt(argv.port) : 3000;
const api_key = argv.api_key ? argv.api_key : null;
const agent_id = argv.agent_id ? argv.agent_id : null;

assert.ok(api_key, "Retell api key not provided");
assert.ok(agent_id, "Retell agent id not provided");

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
  const call_id = await registerCall();
  res.writeHead(200, { "Content-Type": "application/xml" });
  res.write(makeTwilioConnect(call_id));
  res.end();
});

async function registerCall() {
  const response = await fetch("https://api.retellai.com/register-call", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${api_key}`,
      "Content-type": "application/json",
    },

    body: JSON.stringify({
      agent_id: agent_id,
      audio_websocket_protocol: "twilio",
      audio_encoding: "mulaw",
      sample_rate: 8000,
    }),
  });

  const json = await response.json();
  return json.call_id;
}

function makeTwilioConnect(call_id) {
  const wsUrl = `wss://api.retellai.com/audio-websocket/${call_id}`;

  console.log(`makeTwilioConnect socket url: ${wsUrl}`);
  return `<?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Connect>
      <Stream url="${wsUrl}"></Stream>
    </Connect>
  </Response>`;
}

wsserver.listen(httpPort, function () {
  console.log("Server listening on: http://localhost:%s", httpPort);
});
