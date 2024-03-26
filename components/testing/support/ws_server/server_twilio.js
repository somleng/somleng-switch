// From: https://github.com/drachtio/drachtio-freeswitch-modules/blob/main/examples/ws_server.js

const WebSocket = require("ws");
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


class AudioTestStream {
  audioData = new Buffer();
  chunkMs = 80;
  sampleRate = 8000;
  chunkSize = sampleRate * (chunkMs / 1000.0);

  initializeAudio() {
    this.audioData = new Buffer();
  }

  streamStoredAudio(ws, streamSid) {
    for (let i = 0; i < this.audioData.length / this.chunkSize; i++) {
      const base64Data = this.audioData.subarray(i * this.chunkSize, (i + 1) * this.chunkSize).toString('base64');
      const msg = makeOutboundSample(base64Data, streamSid)

      if (ws)
        ws.send(JSON.stringify(msg))
    }

    const msg = makeMark(base64Data, streamSid)
    if (ws)
      ws.send(JSON.stringify(msg))
  }

  appendAudio(data) {
    this.audioData = Buffer.concat(this.audioData, data)
  }

  makeOutboundSample(base64, streamSid) {
    return {
      "event": "media",
      "media": {
        "payload": base64,
      },
      "streamSid": streamSid
    }
  }

  makeMark(streamSid) {
    return {
      "event": "mark",
      "mark": {
        "name": "audio"
      },
      "streamSid": streamSid
    }
  }
}

const audioStream = new AudioTestStream();
wss.on("connection", (ws, req) => {
  ws.on("message", (message) => {
    if (typeof message === "string") {
      console.log(`received message <string>: ${message}`);
    } else if (message instanceof Buffer) {
      const strMessage = message.toString();
      try {
        const json = JSON.parse(message);
        if (json['event'] === 'start') {
          console.log(`Starting recieve data`);
          audioStream.initializeAudio()
        } else if (json['event'] === 'dtmf') {
          console.log(`Start sending stored data`);
          audioStream.streamStoredAudio(ws);
        } else if (json['event'] === 'media') {
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
