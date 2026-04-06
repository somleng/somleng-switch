const http = require("http");

const port = process.env.CDR_SERVER_PORT || 9000;

function logRequest(req, rawBodyBuffer) {
  // Convert to string ONLY once, after fully receiving the body
  const body = rawBodyBuffer.toString("utf8");

  // Parse URL-encoded body safely
  const params = new URLSearchParams(body);
  const rawBase64 = params.get("cdr") || "";

  // Log raw base64 (what you want for assertions)
  console.log(rawBase64);

  // Optional: debug decode (uncomment if needed)
  /*
  try {
    const decoded = Buffer.from(rawBase64, "base64");
    console.log("---- decoded preview ----");
    console.log(decoded.toString("utf8").slice(0, 200));
  } catch (err) {
    console.error("Failed to decode base64:", err);
  }
  */
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
