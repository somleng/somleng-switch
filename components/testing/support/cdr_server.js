const http = require("http");
const querystring = require("querystring");

const port = process.env.CDR_SERVER_PORT || 9000;

function logRequest(req, body) {
  const params = querystring.parse(body); // parse URL-encoded body
  const rawBase64 = params.cdr || "";

  let decoded = "";
  try {
    decoded = Buffer.from(rawBase64, "base64").toString("utf-8");
  } catch (err) {
    decoded = `[Failed to decode Base64: ${err.message}]`;
  }

  jsonStr = decoded
    .replace(/\bNaN\b/gi, "null")
    .replace(/\bInfinity\b/gi, "null")
    .replace(/\b-Infinity\b/gi, "null")
    .replace(
      /"sip_user_agent"\s*:\s*"([^"]|\\")*?"/gi,
      '"sip_user_agent":"[REMOVED]"'
    );

  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  console.log(JSON.stringify(JSON.parse(jsonStr), null, 2));
  console.log("\n");
}

const server = http.createServer((req, res) => {
  let body = "";

  req.on("data", (chunk) => {
    body += chunk.toString();
  });

  req.on("end", () => {
    logRequest(req, body);
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("OK");
  });
});

server.listen(port, () => {
  console.log(`CDR server running on port ${port}, logging to stdout`);
});
