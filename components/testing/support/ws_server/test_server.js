// Adapted From: https://github.com/twilio/media-streams/blob/master/node/connect-basic/server.js

const WebSocket = require("ws");
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

class AudioTestStream {
  audioData = Buffer.alloc(0);
  streamSid = "";

  initializeAudio(streamSid) {
    this.audioData = Buffer.alloc(0);
    this.streamSid = streamSid;
  }

  streamStoredAudio(ws) {
    console.log(`streamStoredAudio start sending data LEN: ${this.audioData.length}`);
    const base64Data = this.audioData.toString('base64');
    const msg = this.makeOutboundSample(base64Data)

    if (ws) {
      console.log(`${JSON.stringify(msg)}`)
      ws.send(JSON.stringify(msg))
    }
  }

  markAudio(ws) {
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
