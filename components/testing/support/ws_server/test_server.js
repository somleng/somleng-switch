const WebSocket = require("ws");
const AudioTestStream = require("./audio_test_stream.js")

const argv = require("minimist")(process.argv);
const port = argv.port && parseInt(argv.port) ? parseInt(argv.port) : 3001;

const wss = new WebSocket.Server({
  port,
  handleProtocols: () => {
    return "audio.somleng.org";
  },
});

const audioStream = new AudioTestStream();
wss.on("connection", (ws) => {
  ws.on("message", (message) => {
    console.log(`received message: ${message}`);
    console.log(`message type: ${message.type}`);

    if (message.type === "utf8") {
      try {
        const data = JSON.parse(message.utf8Data);
        if (data.event === "connected") {
          log("From Twilio: Connected event received: ", data);
        }
        if (data.event === "start") {
          log("From Twilio: Start event received: ", data);
          audioStream.initializeAudio(data['streamSid'])
        }
        if (data.event === "media") {
          log("From Twilio: Media event received: ", data);
          const b64string = data['media']["payload"]
            audioStream.appendAudio(Buffer.from(b64string, 'base64'))
        }
        if (data.event === "dtmf") {
          log("From Twilio: DTMF event received: ", data);
          audioStream.streamStoredAudio(ws);
        }
        if (data.event === "mark") {
          log("From Twilio: Mark event received", data);
          audioStream.streamStoredAudio(ws);
        }
        if (data.event === "close") {
          log("From Twilio: Close event received: ", data);
          ws.close();
        }
      } catch (e) {
        console.log(`received message <err>: ${message}`);
        console.log(e)
      }
    }
  });

  ws.on("close", (code, reason) => {
    console.log(`socket closed ${code}:${reason}`);
  });
});
