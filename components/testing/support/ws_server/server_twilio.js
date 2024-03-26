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
  audioData = Buffer.alloc(0);
  chunkMs = 80;
  sampleRate = 8000;
  chunkSize = this.sampleRate * (this.chunkMs / 1000.0);
  streamSid = "";
  saveAudio = false;
  audioPath = "";

  initializeAudio(streamSid) {
    this.audioData = Buffer.alloc(0);
    this.streamSid = streamSid;
  }

  streamStoredAudio(ws) {
    console.log(`streamStoredAudio start sending data LEN: ${this.audioData.length}`);
    if(this.saveAudio && this.audioPath) {
      let wstream = fs.createWriteStream(audioPath);
      wstream.write(this.audioData)
      wstream.close()
    }

    for (let i = 0; i < this.audioData.length / this.chunkSize; i++) {
      const base64Data = this.audioData.subarray(i * this.chunkSize, (i + 1) * this.chunkSize).toString('base64');
      const msg = this.makeOutboundSample(base64Data)

      if (ws) {
        console.log(`${JSON.stringify(msg)}`)
        ws.send(JSON.stringify(msg))
      }
    }

    const msg = this.makeMark()
    if (ws) {
      console.log(`${JSON.stringify(msg)}`)
      ws.send(JSON.stringify(msg))
    }
  }

  appendAudio(data) {
    console.log(`Append audio ${this.audioData.length} -> ${data.length}`)
    this.audioData = Buffer.concat([this.audioData, data])
  }

  makeOutboundSample(base64) {
    return {
      "event": "media",
      "media": {
        "payload": base64,
      },
      "streamSid": this.streamSid
    }
  }

  makeMark() {
    return {
      "event": "mark",
      "mark": {
        "name": "audio"
      },
      "streamSid": this.streamSid
    }
  }
}

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
