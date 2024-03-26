// From: https://github.com/drachtio/drachtio-freeswitch-modules/blob/main/examples/ws_server.js

const WebSocket = require("ws");
const AudioTestStream = require("./audio_test_stream.js")
const fs = require("fs");
const WaveFile = require('wavefile').WaveFile;

const argv = require("minimist")(process.argv.slice(2));
const port = argv.port && parseInt(argv.port) ? parseInt(argv.port) : 3001;

const wss = new WebSocket.Server({
  port,
  handleProtocols: (protocols, req) => {
    return "audio.somleng.org";
  },
});

const audioStream = new AudioTestStream();
let isRecord = true;
wss.on("connection", (ws, req) => {
  ws.on("message", (message) => {
    if (typeof message === "string") {
      console.log(`received message <string>: ${message}`);
    } else if (message instanceof Buffer) {
      const strMessage = message.toString();
      try {
        const json = JSON.parse(message);
        if (json['event'] === 'start') {
          isRecord = true;
          console.log(`Starting recieve data`);
          audioStream.initializeAudio(json['streamSid'])
        } else if (json['event'] === 'dtmf') {
          console.log(`Start sending stored data`);
          isRecord = false
          audioStream.streamStoredAudio(ws);
        } else if (json['event'] === 'media') {
          const b64string = json['media']["payload"]
          if(isRecord)
            audioStream.appendAudio(Buffer.from(b64string, 'base64'))
        } else if (json['event'] === 'mark') {
          console.log(`Closing Stream`);
          ws.close();
        }
      } catch (e) {
        console.log(`received message <err>: ${strMessage}`);
        console.log(e)
      }
    }
  });

  ws.on("close", (code, reason) => {
    console.log(`socket closed ${code}:${reason}`);
  });
});
