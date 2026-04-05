const http = require("http");
const querystring = require("querystring");

const port = process.env.CDR_SERVER_PORT || 9000;

function logRequest(req, body) {
  const params = querystring.parse(body); // parse URL-encoded body
  const rawBase64 = params.cdr || "";
  console.log(rawBase64);
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
