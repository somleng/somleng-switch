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
module.exports = AudioTestStream
