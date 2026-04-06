package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/cgrates/fsock"
	"github.com/redis/go-redis/v9"
)

type nopLogger struct{}

func (nopLogger) Alert(string) error   { return nil }
func (nopLogger) Close() error         { return nil }
func (nopLogger) Crit(string) error    { return nil }
func (nopLogger) Debug(string) error   { return nil }
func (nopLogger) Emerg(string) error   { return nil }
func (nopLogger) Err(string) error     { return nil }
func (nopLogger) Info(string) error    { return nil }
func (nopLogger) Notice(string) error  { return nil }
func (nopLogger) Warning(string) error { return nil }

const modTwilioStreamPrefix = "mod_twilio_stream"

type CallPlatformClient struct {
	Host     string
	Username string
	Password string
	Client   *http.Client
}

func NewCallPlatformClient() *CallPlatformClient {
	return &CallPlatformClient{
		Host:     os.Getenv("FS_CALL_PLATFORM_HOST"),
		Username: os.Getenv("FS_CALL_PLATFORM_USERNAME"),
		Password: os.Getenv("FS_CALL_PLATFORM_PASSWORD"),
		Client:   &http.Client{Timeout: 10 * time.Second},
	}
}

func (c *CallPlatformClient) newRequest(method, path string, body any) *http.Request {
	jsonData, _ := json.Marshal(body)

	req, _ := http.NewRequest(method, c.Host+path, bytes.NewBuffer(jsonData))

	req.Header.Set("Content-Type", "application/json")
	req.SetBasicAuth(c.Username, c.Password)

	return req
}

// Formats the event as map and prints it out
func logHeartbeat(eventStr string, connIdx int) {
	// Format the event from string into Go's map type
	eventMap := fsock.FSEventStrToMap(eventStr, []string{})
	jsonString, _ := json.Marshal(eventMap)
	fmt.Println(string(jsonString))
}

func parseCustomEvent(eventStr string) (string, string, error) {
	eventMap := fsock.FSEventStrToMap(eventStr, []string{})

	eventName := eventMap["Event-Subclass"]

	if !strings.HasPrefix(eventName, modTwilioStreamPrefix) {
		fmt.Println("Unhandled Event Type: " + eventName)
		return "", "", fmt.Errorf("Unhandled Event Type: " + eventName)
	}

	eventPayload := make(map[string]any)
	parsePayloadError := json.Unmarshal([]byte(eventMap["Event-Payload"]), &eventPayload)
	if parsePayloadError != nil {
		fmt.Println("Failed to parse Event Payload: " + eventMap["Event-Payload"])
		return "", "", fmt.Errorf("Failed to parse Event Payload: " + eventMap["Event-Payload"])
	}

	streamSid, streamSidExists := eventPayload["streamSid"].(string)
	if !streamSidExists {
		fmt.Println("Event does not contain streamSid: " + eventMap["Event-Payload"])
		return "", "", fmt.Errorf("Event does not contain streamSid: " + eventMap["Event-Payload"])
	}

	redisChannel := modTwilioStreamPrefix + ":" + streamSid
	return redisChannel, eventMap["Event-Payload"], nil
}

func channelEventHandler(eventStr string, connIdx int) {
	event := fsock.FSEventStrToMap(eventStr, []string{})

	// Ignore outbound legs
	if event["Call-Direction"] != "inbound" {
		return
	}

	switch event["Event-Name"] {
	case "CHANNEL_CREATE":
		handleProxyChannelCreate(event)
	}
}

func handleProxyChannelCreate(event map[string]string) {
	if event["variable_sip_h_X-Somleng-CallDirection"] != "outbound" {
		return
	}

	client := NewCallPlatformClient()
	client.UpdateCallProxyIdentifier(
		event["variable_sip_h_X-Somleng-CallSid"],
		event["variable_call_uuid"],
	)
}

func (c *CallPlatformClient) UpdateCallProxyIdentifier(callPlatformId, proxyIdentifier string) {
	go func() {
		payload := map[string]interface{}{
			"phone_call_sid":          callPlatformId,
			"switch_proxy_identifier": proxyIdentifier,
		}

		req := c.newRequest("PATCH", "/phone_calls/"+callPlatformId, payload)
		resp, err := c.Client.Do(req)
		if err != nil {
			println("HTTP request failed:", err.Error())
		}
		defer resp.Body.Close()
	}()
}

func (c *CallPlatformClient) CreateCallHeartbeats(callUUIDs []string) {
	go func() {
		req := c.newRequest("POST", "/call_heartbeats", callUUIDs)
		resp, err := c.Client.Do(req)

		if err != nil {
			println("HTTP request failed:", err.Error())
		}
		defer resp.Body.Close()
	}()
}

func fetchActiveCallUUIDs(fs *fsock.FSock) []string {
	resp, err := fs.SendApiCmd("show channels as json")
	if err != nil {
		return []string{}
	}

	payload := make(map[string]any)
	if err := json.Unmarshal([]byte(resp), &payload); err != nil {
		return []string{}
	}

	rawRows, exists := payload["rows"]
	if !exists {
		return []string{}
	}

	rows := rawRows.([]any)

	uuidSet := make(map[string]struct{})
	for _, row := range rows {
		rowMap := row.(map[string]any)

		// Only include inbound calls
		if direction := rowMap["direction"].(string); direction != "inbound" {
			continue
		}

		uuidSet[rowMap["call_uuid"].(string)] = struct{}{}
	}

	var uuids []string
	for uuid := range uuidSet {
		uuids = append(uuids, uuid)
	}

	return uuids
}

func getCallHeartbeatInterval() time.Duration {
	intervalEnv := os.Getenv("CALL_STATUS_HEARTBEAT_INTERVAL_SECONDS")

	if intervalEnv != "" {
		secs, _ := strconv.Atoi(intervalEnv)
		return time.Duration(secs) * time.Second
	}

	return 30 * time.Second
}

func callStatusUpdates(fs *fsock.FSock, callPlatformClient *CallPlatformClient) {
	ticker := time.NewTicker(getCallHeartbeatInterval())
	defer ticker.Stop()

	for range ticker.C {
		callUUIDs := fetchActiveCallUUIDs(fs)

		if len(callUUIDs) == 0 {
			continue
		}

		callPlatformClient.CreateCallHeartbeats(callUUIDs)
	}
}

func customEventHandler(ctx context.Context, redisClient *redis.Client, eventStr string) {
	redisChannel, redisMsg, parseEventError := parseCustomEvent(eventStr)

	if parseEventError != nil {
		fmt.Println("Error: " + parseEventError.Error())
		return
	}

	redisError := redisClient.Publish(ctx, redisChannel, redisMsg).Err()
	if redisError != nil {
		fmt.Println("Problem publishing to Redis channel: " + redisChannel + " Payload: " + redisMsg + " Error: " + redisError.Error())
	}
}

func fibDuration(durationUnit, maxDuration time.Duration) func() time.Duration {
	a, b := 0, 1
	return func() time.Duration {
		a, b = b, a+b
		fibNrAsDuration := time.Duration(a) * durationUnit
		if maxDuration > 0 && maxDuration < fibNrAsDuration {
			return maxDuration
		}
		return fibNrAsDuration
	}
}

func main() {
	ctx := context.Background()

	redisUrl := os.Getenv("REDIS_URL")
	redisOptions, redisError := redis.ParseURL(redisUrl)

	if redisError != nil {
		panic(redisError)
	}

	redisClient := redis.NewClient(redisOptions)

	customEventHandlerWrapper := func(eventStr string, connIdx int) {
		customEventHandler(ctx, redisClient, eventStr)
	}

	evFilters := map[string][]string{
		"Event-Name": {
			"HEARTBEAT",
			"CUSTOM",
			"CHANNEL_CREATE",
		},
	}

	evHandlers := map[string][]func(string, int){
		"HEARTBEAT":      {logHeartbeat},
		"ALL":            {customEventHandlerWrapper},
		"CHANNEL_CREATE": {channelEventHandler},
	}

	event_socket_host := os.Getenv("EVENT_SOCKET_HOST")
	event_socket_password := os.Getenv("EVENT_SOCKET_PASSWORD")

	errChan := make(chan error)
	fs, err := fsock.NewFSock(event_socket_host, event_socket_password, 10, 60, 0, fibDuration, evHandlers, evFilters, nopLogger{}, 0, false, errChan)
	if err != nil {
		fmt.Printf("FreeSWITCH error: %s\n", err)
		return
	}

	callPlatformClient := NewCallPlatformClient()

	go callStatusUpdates(fs, callPlatformClient)

	<-errChan
}
