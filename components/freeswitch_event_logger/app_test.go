package main

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type capturedRequest struct {
	method   string
	path     string
	username string
	password string
	body     map[string]any
}

func TestParseEventFail(t *testing.T) {
	_, _, parseEventError := parseCustomEvent("")
	require.Error(t, parseEventError)
}

func TestParseEvent(t *testing.T) {
	incomingMsg :=
		`Event-Subclass: mod_twilio_stream%3A%3Adisconnect
Event-Name: CUSTOM
Core-UUID: 972157ac-e4e8-41b5-bd8b-26e904729226
Event-Payload: %7B%22event%22%3A%20%22disconnect%22,%22accountSid%22%3A%20%22c4612957-a00a-480d-a168-c75fbf29b2db%22,%22callSid%22%3A%20%2221fb5eee-ce7c-4e30-a069-439fa0269aeb%22,%22streamSid%22%3A%20%225cc24afd-ea42-4605-858d-5c47b597b646%22%7D`

	wantRedisChannel := `mod_twilio_stream:5cc24afd-ea42-4605-858d-5c47b597b646`
	wantRedisMsg := `{"event": "disconnect","accountSid": "c4612957-a00a-480d-a168-c75fbf29b2db","callSid": "21fb5eee-ce7c-4e30-a069-439fa0269aeb","streamSid": "5cc24afd-ea42-4605-858d-5c47b597b646"}`

	redisChannel, redisMsg, parseEventError := parseCustomEvent(incomingMsg)

	require.NoError(t, parseEventError)
	assert.Equal(t, wantRedisChannel, redisChannel)
	assert.Equal(t, wantRedisMsg, redisMsg)
}

func TestCreateCallHeartbeats(t *testing.T) {
	server, requests := newRequestCaptureServer(t)
	defer server.Close()

	client := buildStubCallPlatformClient(server)

	client.CreateCallHeartbeats([]string{"uuid-1", "uuid-2"})
	req := waitForRequest(t, requests)

	assert.Equal(t, http.MethodPost, req.method)
	assert.Equal(t, "/call_heartbeats", req.path)

	callIDs, ok := req.body["call_ids"].([]any)
	require.True(t, ok, "Unexpected payload type for call_ids got %#v", req.body["call_ids"])
	assert.Equal(t, []any{"uuid-1", "uuid-2"}, callIDs)
}

func buildStubCallPlatformClient(server *httptest.Server) *CallPlatformClient {
	return &CallPlatformClient{
		Host:     server.URL,
		Username: "test-user",
		Password: "test-pass",
		Client:   server.Client(),
	}
}

func newRequestCaptureServer(t *testing.T) (*httptest.Server, <-chan capturedRequest) {
	t.Helper()

	requests := make(chan capturedRequest, 1)
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Helper()

		rawBody, err := io.ReadAll(r.Body)
		if err != nil {
			t.Fatalf("failed to read request body: %v", err)
		}

		var payload map[string]any
		if err := json.Unmarshal(rawBody, &payload); err != nil {
			t.Fatalf("failed to decode request body: %v", err)
		}

		username, password, _ := r.BasicAuth()

		requests <- capturedRequest{
			method:   r.Method,
			path:     r.URL.Path,
			username: username,
			password: password,
			body:     payload,
		}

		w.WriteHeader(http.StatusOK)
	}))

	return server, requests
}

func waitForRequest(t *testing.T, requests <-chan capturedRequest) capturedRequest {
	t.Helper()

	select {
	case req := <-requests:
		return req
	case <-time.After(2 * time.Second):
		t.Fatal("timed out waiting for request")
		return capturedRequest{}
	}
}

func waitForNoRequest(t *testing.T, requests <-chan capturedRequest) {
	t.Helper()

	select {
	case req := <-requests:
		t.Fatalf("received unexpected request: %#v", req)
	case <-time.After(300 * time.Millisecond):
	}
}
