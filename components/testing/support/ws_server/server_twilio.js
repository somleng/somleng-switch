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

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))
const streamAudio = async (ws) => {

  const chunkMs = 20;
  const chunkSize = sampleRate * (chunkMs / 1000.0);

  const testWav = new WaveFile(fs.readFileSync("test.wav"));
  testWav.toSampleRate(sampleRate)
  testWav.toMuLaw();
  const buf = Buffer.from(testWav.data.samples);
  const millis = Date.now();
  for (let i = 0; i < Math.min(3, buf.length / chunkSize); i++) {
    const base64Data = buf.subarray(i * chunkSize, (i + 1) * chunkSize).toString('base64');
    const msg = makeOutboundSample(base64Data, i, millis + i * chunkMs)
    console.log(msg);
    if (ws)
      ws.send(JSON.stringify(msg))
    await sleep(chunkSize);
  }
}

const makeOutboundSample = (base64, chunkIndex, timestamp) => {
  return {
    "event": "media",
    "sequenceNumber": seq++,
    "media": {
      "track": "outbound",
      "chunk": chunkIndex + 1,
      "timestamp": timestamp,
      "payload": base64,
    },
    "streamSid": "MZ18ad3ab5a668481ce02b83e7395059f0"
  }
}



console.log('mod_audio_fork_test server 2 start');
wss.on("connection", (ws, req) => {
  console.log(`received connection from ${req.connection.remoteAddress}`);

  wstream = fs.createWriteStream(recordingPath);
  //streamAudio(ws);

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
        }
      } catch (e) { 
        console.log(`received message <err>: ${strMessage}`);
        console.log(e)}
    }
  });

  ws.on("close", (code, reason) => {
    console.log(`socket closed ${code}:${reason}`);
    wstream.end();
  });




});
