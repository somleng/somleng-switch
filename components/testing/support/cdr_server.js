const http = require("http");

const port = process.env.CDR_SERVER_PORT || 9000;

function logRequest(req, rawBodyBuffer) {
  const body = rawBodyBuffer.toString("utf8");

  const params = new URLSearchParams(body);
  const rawBase64 = params.get("cdr") || "";

  console.log(rawBase64);
}

const server = http.createServer((req, res) => {
  const chunks = [];

  req.on("data", (chunk) => {
    chunks.push(chunk); // keep raw bytes
  });

  req.on("end", () => {
    const rawBodyBuffer = Buffer.concat(chunks);

    logRequest(req, rawBodyBuffer);

    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("OK");
  });

  req.on("error", (err) => {
    console.error("Request error:", err);
    res.writeHead(500);
    res.end("Error");
  });
});

server.listen(port, () => {
  console.log(`CDR server running on port ${port}, logging to stdout`);
});
