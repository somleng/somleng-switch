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

const modTwilioStreamPrefix = "mod_twilio_stream"

type CallPlatformClient struct {
	Host     string
	Username string
	Password string
	Client   *http.Client
}

func NewCallPlatformClient() *CallPlatformClient {
	return &CallPlatformClient{
		Host:     os.Getenv("CALL_PLATFORM_HOST"),
		Username: os.Getenv("CALL_PLATFORM_USERNAME"),
		Password: os.Getenv("CALL_PLATFORM_PASSWORD"),
		Client:   &http.Client{Timeout: 10 * time.Second},
	}
}

func NewRedisClient() *redis.Client {
	redisUrl := os.Getenv("REDIS_URL")
	redisOptions, redisError := redis.ParseURL(redisUrl)
	if redisError != nil {
		panic(redisError)
	}

	return redis.NewClient(redisOptions)
}

func NewEventSocketClient(eventHandlers map[string][]func(string, int), eventFilters map[string][]string, errChan chan error) *fsock.FSock {
	event_socket_host := os.Getenv("EVENT_SOCKET_HOST")
	event_socket_password := os.Getenv("EVENT_SOCKET_PASSWORD")

	fs, err := fsock.NewFSock(event_socket_host, event_socket_password, 10, 60, 0, fibDuration, eventHandlers, eventFilters, nil, 0, false, errChan)
	if err != nil {
		fmt.Printf("FreeSWITCH error: %s\n", err)
		panic(err)
	}

	return fs
}

func (c *CallPlatformClient) newRequest(method, path string, body any) *http.Request {
	jsonData, _ := json.Marshal(body)

	req, _ := http.NewRequest(method, c.Host+path, bytes.NewBuffer(jsonData))

	req.Header.Set("Content-Type", "application/json")
	req.SetBasicAuth(c.Username, c.Password)

	return req
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

func (c *CallPlatformClient) CreateCallHeartbeats(callUUIDs []string) {
	go func() {
		payload := map[string]interface{}{
			"call_ids": callUUIDs,
		}

		req := c.newRequest("POST", "/call_heartbeats", payload)
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

	redisClient := NewRedisClient()
	customEventHandlerWrapper := func(eventStr string, connIdx int) {
		customEventHandler(ctx, redisClient, eventStr)
	}

	evFilters := map[string][]string{
		"Event-Name": {
			"CUSTOM",
		},
	}

	evHandlers := map[string][]func(string, int){
		"ALL": {customEventHandlerWrapper},
	}

	errChan := make(chan error)
	eventSocketClient := NewEventSocketClient(evHandlers, evFilters, errChan)
	callPlatformClient := NewCallPlatformClient()

	go callStatusUpdates(eventSocketClient, callPlatformClient)

	<-errChan
}
