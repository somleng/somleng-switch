import { createServer } from "node:http";
import crypto from "node:crypto";
import { z } from "zod";

const hostname = "0.0.0.0";
const port = 3000;

const { CONNECT_WS_SERVER_URL, AUDIO_FILE_URL, CARRIER_SID, ACCOUNT_SID } =
  process.env;

const connectWsServerUrl = CONNECT_WS_SERVER_URL || "wss://example.com";
const audioFileUrl = AUDIO_FILE_URL || "https://api.twilio.com/cowbell.mp3";

const DEFAULT_TEST_NUMBER = {
  twimlResponse:
    "<Response><Play>https://demo.twilio.com/docs/classic.mp3</Play></Response>",
  billingEnabled: false,
};
const FORBIDDEN_TEST_NUMBER = "4444";
const TEST_NUMBERS = {
  1111: {
    twimlResponse: "<Response><Say>Hello World!</Say><Hangup /></Response>",
    billingEnabled: false,
  },
  2222: {
    twimlResponse: `
      <Response>
        <Connect>
          <Stream url="${connectWsServerUrl}">
            <Parameter name="aCustomParameter" value="aCustomValue that was set in TwiML" />
          </Stream>
        </Connect>
        <Play>${audioFileUrl}</Play>
      </Response>`,
    billingEnabled: false,
  },
  3333: {
    twimlResponse: "<Response><Say>Hello World!</Say><Hangup /></Response>",
    billingEnabled: true,
  },
  5555: {
    twimlResponse: "<Response><Dial>85510551006</Dial></Response>",
    billingEnabled: true,
  },
  6666: {
    twimlResponse: "<Response><Reject /></Response>",
    billingEnabled: true,
  },
};

class AuthenticationError extends Error {
  constructor(message) {
    super(message);
    this.name = "AuthenticationError";
  }
}

const InboundPhoneCallsSchema = z.object({
  to: z.string(),
  from: z.string(),
  external_id: z.string(),
  host: z.string(),
  source_ip: z.string(),
  region: z.string(),
  client_identifier: z.string().optional().nullable(),
  variables: z.object({
    sip_from_host: z.string(),
    sip_to_host: z.string(),
    sip_network_ip: z.string(),
    sip_via_host: z.string(),
  }),
});

const PhoneCallUpdateSchema = z.object({
  switch_proxy_identifier: z.string(),
});

const CallHeartbeatSchema = z.object({
  switch_proxy_identifiers: z.array(z.string()).min(1),
});

const server = createServer(async (req, res) => {
  try {
    if (req.url === "/health_checks") {
      res.statusCode = 200;
      res.end(JSON.stringify({}));
      return;
    }

    if (req.headers["content-type"] !== "application/json") {
      res.statusCode = 400;
      res.end(JSON.stringify({ error: "Unsupported Media Type" }));
      return;
    }

    authenticate(req);

    res.statusCode = 201;
    res.setHeader("Content-Type", "application/json");

    switch (req.url) {
      case "/phone_call_events":
      case "/tts_events":
      case "/media_stream_events":
        assertHTTPMethod(req, "POST");

        res.end(JSON.stringify({}));
        break;
      case "/inbound_phone_calls":
        assertHTTPMethod(req, "POST");
        await handleInboundPhoneCalls(req, res);
        break;
      case "/outbound_phone_calls":
        assertHTTPMethod(req, "POST");
        await handleOutboundPhoneCalls(req, res);
        break;
      case "/media_streams":
        assertHTTPMethod(req, "POST");
        await handleMediaStreams(req, res);
        break;
      case "/call_heartbeats":
        handleCallHeartbeats(req, res);
        break;
      default:
        if (req.url.startsWith("/recordings")) {
          await handleRecordings(req, res);
          return;
        } else if (req.url.startsWith("/phone_calls")) {
          await handlePhoneCallUpdate(req, res);
          return;
        }

        res.statusCode = 404;
        res.end(JSON.stringify({ error: "Not Found" }));
    }
  } catch (error) {
    console.error("Error:", error);

    if (error instanceof AuthenticationError) {
      res.statusCode = 401;
      res.end(JSON.stringify({ error: "Unauthorized" }));
    } else {
      res.statusCode = 500;
      res.end(JSON.stringify({ error: "Internal Server Error" }));
    }
  }
});

const authenticate = (req) => {
  const authHeader = req.headers["authorization"];
  if (!authHeader) {
    throw new AuthenticationError("Unauthorized");
  }

  const { CALL_PLATFORM_USERNAME, CALL_PLATFORM_PASSWORD } = process.env;
  if (!CALL_PLATFORM_USERNAME || !CALL_PLATFORM_PASSWORD) {
    throw new Error(
      "CALL_PLATFORM_USERNAME and CALL_PLATFORM_PASSWORD must be set",
    );
  }

  const base64Credentials = authHeader.split(" ")[1];
  const credentials = Buffer.from(base64Credentials, "base64").toString("utf8");
  const [username, password] = credentials.split(":");

  if (
    username !== CALL_PLATFORM_USERNAME ||
    password !== CALL_PLATFORM_PASSWORD
  ) {
    throw new AuthenticationError("Unauthorized");
  }
};

const handleInboundPhoneCalls = async (req, res) => {
  const data = await parseBody(req);
  const { to, from } = InboundPhoneCallsSchema.parse(data);
  const destination = to.replace(/\D/g, "");

  if (destination === FORBIDDEN_TEST_NUMBER) {
    res.statusCode = 422;
    res.end(JSON.stringify({ error: "Unprocessable Entity" }));
    return;
  }

  const testNumber =
    destination in TEST_NUMBERS
      ? TEST_NUMBERS[destination]
      : DEFAULT_TEST_NUMBER;
  const response = {
    voice_url: null,
    voice_method: null,
    twiml: testNumber.twimlResponse,
    carrier_sid: CARRIER_SID,
    account_sid: ACCOUNT_SID,
    account_auth_token: crypto.randomUUID(),
    sid: crypto.randomUUID(),
    direction: "inbound",
    call_direction: "inbound",
    to: destination,
    from,
    api_version: "2010-04-01",
    default_tts_voice: "Basic.Kal",
    billing_parameters: {
      enabled: testNumber.billingEnabled,
      category: "inbound_calls",
      billing_mode: "prepaid",
    },
  };

  res.end(JSON.stringify(response));
};

const handleOutboundPhoneCalls = async (req, res) => {
  const data = await parseBody(req);
  const { parent_call_sid, destinations } = data;

  const response = {
    phone_calls: destinations.map((to) => ({
      sid: crypto.randomUUID(),
      parent_call_sid,
      account_sid: ACCOUNT_SID,
      carrier_sid: CARRIER_SID,
      from: "1234",
      call_direction: "outbound",
      routing_parameters: {
        address: null,
        destination: to,
        dial_string_prefix: null,
        plus_prefix: false,
        national_dialing: false,
        host: "testing",
        username: null,
        sip_profile: "nat_gateway",
      },
      billing_parameters: {
        enabled: true,
        category: "outbound_calls",
        billing_mode: "prepaid",
      },
    })),
  };

  res.end(JSON.stringify(response));
};

const handleRecordings = async (req, res) => {
  if (req.url === "/recordings") {
    assertHTTPMethod(req, "POST");
  } else {
    assertHTTPMethod(req, "PATCH");
  }

  res.end(
    JSON.stringify({
      sid: crypto.randomUUID(),
      url: "https://api.somleng.org/cowbell.mp3",
    }),
  );
};

const handlePhoneCallUpdate = async (req, res) => {
  assertHTTPMethod(req, "PATCH");
  const data = await parseBody(req);
  PhoneCallUpdateSchema.parse(data);

  res.statusCode = 204;

  res.end(JSON.stringify({}));
};

const handleCallHeartbeats = async (req, res) => {
  assertHTTPMethod(req, "POST");
  const data = await parseBody(req);
  CallHeartbeatSchema.parse(data);

  res.statusCode = 204;

  res.end(JSON.stringify({}));
};

const handleMediaStreams = async (_req, res) => {
  res.end(JSON.stringify({ sid: crypto.randomUUID() }));
};

const parseBody = async (req) => {
  const body = await new Response(req).text();
  return body ? JSON.parse(body) : {};
};

const assertHTTPMethod = (req, method) => {
  if (req.method !== method) {
    throw new Error(`Expected ${method} request, got ${req.method}`);
  }
};

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});
