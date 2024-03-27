const fs = require("fs");
const path = require("path");
var http = require("http");
var HttpDispatcher = require("httpdispatcher");
var WebSocketServer = require("websocket").server;
const AudioTestStream = require("./audio_test_stream.js")

var dispatcher = new HttpDispatcher();
var wsserver = http.createServer(handleRequest);

const HTTP_SERVER_PORT = 8080;

var mediaws = new WebSocketServer({
  httpServer: wsserver,
  autoAcceptConnections: true,
});

function log(message, ...args) {
  console.log(new Date(), message, ...args);
}

function handleRequest(request, response) {
  try {
    dispatcher.dispatch(request, response);
  } catch (err) {
    console.error(err);
  }
}

dispatcher.onPost("/connect", function (req, res) {
  log("POST connect");

  var filePath = path.join(__dirname + "/templates", "streams.xml");
  var stat = fs.statSync(filePath);

  res.writeHead(200, {
    "Content-Type": "text/xml",
    "Content-Length": stat.size,
  });

  var readStream = fs.createReadStream(filePath);
  readStream.pipe(res);
});

mediaws.on("connect", function (connection) {
  log("From Twilio: Connection accepted");
  new MediaStream(connection);
});

class MediaStream {
  constructor(connection) {
    this.connection = connection;
    connection.on("message", this.processMessage.bind(this));
    connection.on("close", this.close.bind(this));
    this.hasSeenMedia = false;
    this.messages = [];
    this.repeatCount = 0;

    this.isRecord = true;
    this.audioStream = new AudioTestStream();
  }

  processMessage(message) {
    log(message)
    if (message.type === "utf8") {
      try {
        const data = JSON.parse(message.utf8Data);
        if (data.event === "connected") {
          log("From Twilio: Connected event received: ", data);
        }
        if (data.event === "start") {
          log("From Twilio: Start event received: ", data);
          this.isRecord = true;
          this.audioStream.initializeAudio(data.streamSid)
        }
        if (data.event === 'dtmf') {
          log(`Start sending stored data`);
          this.isRecord = false
          this.audioStream.streamStoredAudio(ws);
          this.audioStream.markAudio(ws);
        }
        if (data.event === "media") {
          const b64string = data.media.payload
          if (this.isRecord)
            this.audioStream.appendAudio(Buffer.from(b64string, 'base64'))

        }
        if (data.event === "mark") {
          log("From Twilio: Mark event received", data);
          this.close();
        }
        if (data.event === "close") {
          log("From Twilio: Close event received: ", data);
          this.close();
        }
      } catch (e) {
        console.log(e)
      }
    } else if (message.type === "binary") {
      log("From Twilio: binary message received (not supported)");
    }
  }

  close() {
    log("Server: Closed");
    this.connection.close(1000, "Shutdown");
  }
}

wsserver.listen(HTTP_SERVER_PORT, function () {
  log("Server listening on: http://localhost", HTTP_SERVER_PORT);
});
