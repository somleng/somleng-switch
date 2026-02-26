import { createServer } from 'node:http'
import crypto from 'node:crypto'

const hostname = '127.0.0.1'
const port = 3000

const { CONNECT_WS_SERVER_URL, AUDIO_FILE_URL } = process.env

const connectWsServerUrl = CONNECT_WS_SERVER_URL || 'wss://example.com'
const audioFileUrl = AUDIO_FILE_URL || 'https://api.twilio.com/cowbell.mp3'

const DEFAULT_TEST_NUMBER = {
  twimlResponse: '<Response><Play>https://demo.twilio.com/docs/classic.mp3</Play></Response>'
}
const TEST_NUMBERS = {
  '1111': {
    twimlResponse: '<Response><Say>Hello World!</Say><Hangup /></Response>'
  },
  '2222': {
    twimlResponse: `
      <Response>
        <Connect>
          <Stream url="${connectWsServerUrl}">
            <Parameter name="aCustomParameter" value="aCustomValue that was set in TwiML" />
          </Stream>
        </Connect>
        <Play>${audioFileUrl}</Play>
      </Response>`
  },
}

const parseBody = async (req) => {
  const body = await new Response(req).text()
  return body ? JSON.parse(body) : {}
}

const server = createServer(async (req, res) => {
  res.statusCode = 200
  res.setHeader('Content-Type', 'application/json')

  const { to, from } = await parseBody(req)

  const testNumber = to in TEST_NUMBERS ? TEST_NUMBERS[to] : DEFAULT_TEST_NUMBER
  const response = {
    voice_url: null,
    voice_method: null,
    twiml: testNumber.twimlResponse,
    account_sid: crypto.randomUUID(),
    auth_token: crypto.randomUUID(),
    call_sid: crypto.randomUUID(),
    direction: "inbound",
    to,
    from,
    api_version: "2010-04-01",
    default_tts_voice: "Basic.Kal"
  }

  res.end(JSON.stringify(response))
})

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`)
})
