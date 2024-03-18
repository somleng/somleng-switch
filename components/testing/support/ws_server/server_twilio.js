// From: https://github.com/drachtio/drachtio-freeswitch-modules/blob/main/examples/ws_server.js

const WebSocket = require("ws");
const fs = require("fs");
const WaveFile = require('wavefile').WaveFile;

const argv = require("minimist")(process.argv.slice(2));
const recordingPath = argv._.length ? argv._[0] : "/home/jstahlba/audio.ulaw";
const port = argv.port && parseInt(argv.port) ? parseInt(argv.port) : 3001;
const sampleRate = 8000;
const channels = 1;
let seq = 1;
let wstream;

console.log(`listening on port ${port}, writing incoming raw audio to file ${recordingPath}`);

const wss = new WebSocket.Server({
  port,
  handleProtocols: (protocols, req) => {
    return "audio.somleng.org";
  },
});
let streamSid = "";
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))
const streamAudio = async (ws) => {
  const chunkMs = 80;
  const chunkSize = sampleRate * (chunkMs / 1000.0);

  const testWav = new WaveFile(fs.readFileSync("files/taunt.wav"));
  testWav.toSampleRate(sampleRate)
  testWav.toMuLaw();
  const buf = Buffer.from(testWav.data.samples);
  for (let i = 0; i < buf.length / chunkSize; i++) {
    const base64Data = buf.subarray(i * chunkSize, (i + 1) * chunkSize).toString('base64');
    const msg = makeOutboundSample(base64Data)

    if (ws)
      ws.send(JSON.stringify(msg))

      /*
    if (i == ((buf.length / chunkSize) / 2)) {
      if (ws)
        ws.send(JSON.stringify(makeMark("Play Taunt!")))
      sleep(20)
      if (ws)
        ws.send(JSON.stringify(makeClear()))
    }

    if (i == Math.floor((buf.length / chunkSize) * 0.75)) {
      if (ws)
        ws.send(JSON.stringify(makeMark("Play Taunt!")))
      sleep(20)
      if (ws)
        ws.send(JSON.stringify(makeClear()))
    }
    */
  }


}

const makeOutboundSample = (base64) => {
  return {
    "event": "media",
    "media": {
      "payload": base64,
    },
    "streamSid": streamSid
  }
}

const makeMark = (name) => {
  return {
    "event": "mark",
    "mark": {
      "name": name,
    },
    "streamSid": streamSid
  }
}

const makeClear = () => {
  return {
    "event": "clear",
    "streamSid": streamSid
  }
}


console.log('mod_audio_fork_test server 2 start');
wss.on("connection", (ws, req) => {
  console.log(`received connection from ${req.connection.remoteAddress}`);

  wstream = fs.createWriteStream(recordingPath);

  ws.on("message", (message) => {
    if (typeof message === "string") {
      console.log(`received message <string>: ${message}`);
    } else if (message instanceof Buffer) {
      const strMessage = message.toString();

      try {
        const json = JSON.parse(message);
        if (json['event'] === 'media') {
          const b64string = json['media']["payload"]
          wstream.write(Buffer.from(b64string, 'base64'))
        } else {
          console.log(`received message: ${strMessage}`);

          const json = JSON.parse(strMessage);
          if (json.event == "start") {
            streamSid = json.streamSid;
            streamAudio(ws);
          } else if (json.event == "dtmf") {

          }
        }
      } catch (e) {
        console.log(`received message <err>: ${strMessage}`);
        console.log(e)
      }
    }
  });

  ws.on("close", (code, reason) => {
    console.log(`socket closed ${code}:${reason}`);
    wstream.end();
  });
});
