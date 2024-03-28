// Adapted From: https://github.com/twilio/media-streams/blob/master/node/connect-basic/server.js

const WebSocket = require("ws");
const AudioTestStream = require("./audio_test_stream.js")

const argv = require("minimist")(process.argv.slice(2));
const port = argv.port && parseInt(argv.port) ? parseInt(argv.port) : 3001;

const wss = new WebSocket.Server({
  port,
  handleProtocols: () => {
    return "audio.somleng.org";
  },
});

function log(message, ...args) {
  console.log(new Date(), message, ...args);
}

const audioStream = new AudioTestStream();
let isRecord = true;

wss.on("connection", (ws) => {
  ws.on("message", (message) => {
    if (typeof message === "string") {
      console.log(`received message <string>: ${message}`);
    }
    if (message instanceof Buffer) {
      const strMessage = message.toString();
      try {
        const data = JSON.parse(strMessage);
        if (data.event === "connected") {
          log("From Somleng: Connected event received: ", data);
        }
        if (data.event === "start") {
          log("From Somleng: Start event received: ", data);
          isRecord = true;
          audioStream.initializeAudio(data.streamSid);
        }
        if (data.event === "dtmf") {
          log("From Somleng: DTMF event received: ", data);
          log(`Start sending stored data`);
          isRecord = false
          audioStream.streamStoredAudio(ws);
          audioStream.markAudio(ws);
        }
        if (data.event === "media") {
          log("From Somleng: Media event received", data);

          const b64string = data.media.payload
          if(isRecord)
            audioStream.appendAudio(Buffer.from(b64string, 'base64'));
        }
        if (data.event === "mark") {
          log("From Somleng: Mark event received.", data);
          log("Closing Stream");
          ws.close();
        }
        if (data.event === "close") {
          log("From Somleng: Close event received: ", data);
          ws.close();
        }
      } catch (e) {
        console.log(e)
      }
    } else {
      log("From Somleng: Unsupported message", message);
    }
  });

  ws.on("close", (code, reason) => {
    log(`socket closed ${code}:${reason}`);
  });
});
