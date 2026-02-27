import { createServer } from 'node:http'
import crypto from 'node:crypto'

const hostname = '0.0.0.0'
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

const server = createServer(async (req, res) => {
  try {
    res.statusCode = 201
    res.setHeader('Content-Type', 'application/json')

    switch(req.url) {
      case '/health_checks':
        res.statusCode = 200
      case '/services/phone_call_events':
      case '/services/tts_events':
      case '/services/media_stream_events':
        res.end(JSON.stringify({}))
        break
      case '/services/inbound_phone_calls':
        await handleInboundPhoneCalls(req, res)
        break
      case '/services/outbound_phone_calls':
        await handleOutboundPhoneCalls(req, res)
        break
      case '/services/media_streams':
        await handleMediaStreams(req, res)
        break
      default:
        if (req.url.startsWith('/services/recordings')) {
          await handleRecordings(req, res)
          return
        }

        res.statusCode = 404
        res.end(JSON.stringify({ error: 'Not Found' }))
    }
  } catch (error) {
    console.error(error)
    res.statusCode = 500
    res.end(JSON.stringify({ error: 'Internal Server Error' }))
  }
})

const handleInboundPhoneCalls = async (req, res) => {
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
}

const handleOutboundPhoneCalls = async (req, res) => {
  const { parent_call_sid } = await parseBody(req)

  const response = {
    phone_calls: [
      {
        sid: crypto.randomUUID(),
        parent_call_sid,
        account_sid: crypto.randomUUID(),
        carrier_sid: crypto.randomUUID(),
        from: "1234",
        call_direction: "outbound",
        routing_parameters: {
          address: null,
          destination: "8551055100678",
          dial_string_prefix: null,
          plus_prefix: false,
          national_dialing: false,
          host: "27.109.112.141",
          username: null,
          sip_profile: "nat_gateway"
        },
        billing_parameters: {
          enabled: false,
          category: "outbound_calls",
          billing_mode: "prepaid"
        }
      }
    ]
  }


  res.end(JSON.stringify(response))
}

const handleRecordings = async (_req, res) => {
  res.end(JSON.stringify({ sid: crypto.randomUUID(), url: 'https://api.somleng.org/cowbell.mp3'}))
}

const handleMediaStreams = async (_req, res) => {
  res.end(JSON.stringify({ sid: crypto.randomUUID() }))
}

const parseBody = async (req) => {
  const body = await new Response(req).text()
  return body ? JSON.parse(body) : {}
}

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`)
})
