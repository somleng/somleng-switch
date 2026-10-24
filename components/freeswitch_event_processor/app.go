package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/cgrates/fsock"
	"github.com/getsentry/sentry-go"
	"github.com/redis/go-redis/v9"
)

const modTwilioStreamPrefix = "mod_twilio_stream"

type CallPlatformClient struct {
	Host     string
	Username string
	Password string
	Client   *http.Client
}

type FSockClient interface {
	SendApiCmd(cmd string) (string, error)
}

type AppError struct {
	Err           error
	ErrorTracking bool
}

func (e *AppError) Error() string {
	return e.Err.Error()
}

func (e *AppError) Unwrap() error {
	return e.Err
}

func initSentry() {
	err := sentry.Init(sentry.ClientOptions{
		Dsn:         os.Getenv("SENTRY_DSN"),
		Environment: os.Getenv("APP_ENV"),
	})

	if err != nil {
		log.Fatalf("sentry.Init: %s", err)
	}
}

func NewAppError(err error) error {
	return &AppError{
		Err: err,
	}
}

func TrackError(err error) error {
	return &AppError{
		Err:           err,
		ErrorTracking: true,
	}
}

func NewCallPlatformClient() *CallPlatformClient {
	return &CallPlatformClient{
		Host:     os.Getenv("CALL_PLATFORM_HOST"),
		Username: os.Getenv("CALL_PLATFORM_USERNAME"),
		Password: os.Getenv("CALL_PLATFORM_PASSWORD"),
		Client:   &http.Client{Timeout: 20 * time.Second},
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
	eventSocketHost := os.Getenv("EVENT_SOCKET_HOST")
	eventSocketPassword := os.Getenv("EVENT_SOCKET_PASSWORD")

	fs, err := fsock.NewFSock(eventSocketHost, eventSocketPassword, 10, 60, 0, fibDuration, eventHandlers, eventFilters, nil, 0, false, errChan)
	if err != nil {
		sentry.CaptureException(err)
		fmt.Printf("FreeSWITCH error: %s\n", err)
		panic(err)
	}

	return fs
}

func getHealthPort() string {
	port := os.Getenv("HEALTHCHECK_PORT")
	if port == "" {
		port = "8080"
	}
	return port
}

func checkFSock(fs FSockClient) error {
	done := make(chan error, 1)

	go func() {
		_, err := fs.SendApiCmd("status")
		done <- err
	}()

	select {
	case err := <-done:
		return err
	case <-time.After(3 * time.Second):
		return fmt.Errorf("fsock timeout")
	}
}

func startHealthServer(fs FSockClient, redisClient *redis.Client) {
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		fsErr := checkFSock(fs)

		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		redisErr := redisClient.Ping(ctx).Err()

		if fsErr != nil || redisErr != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			w.Write([]byte("unhealthy"))
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	port := getHealthPort()

	go func() {
		log.Printf("Health server running on :%s\n", port)
		if err := http.ListenAndServe(":"+port, nil); err != nil {
			log.Fatalf("health server failed: %v", err)
		}
	}()
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
		return "", "", NewAppError(
			fmt.Errorf("Unhandled Event Type: %s", eventName),
		)
	}

	eventPayload := make(map[string]any)
	parsePayloadError := json.Unmarshal([]byte(eventMap["Event-Payload"]), &eventPayload)

	if parsePayloadError != nil {
		return "", "", TrackError(
			fmt.Errorf("Failed to parse Event Payload: %s", eventMap["Event-Payload"]),
		)
	}

	streamSid, streamSidExists := eventPayload["streamSid"].(string)
	if !streamSidExists {
		return "", "", TrackError(
			fmt.Errorf("Event does not contain streamSid: %s", eventMap["Event-Payload"]),
		)
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
			sentry.CaptureException(err)
			println("HTTP request failed:", err.Error())
			return
		}
		defer resp.Body.Close()
	}()
}

func fetchActiveCallUUIDs(fs FSockClient) []string {
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

		// Filter out channels where SIP state is already DOWN
		callState, _ := rowMap["callstate"].(string)
		if callState == "DOWN" {
			continue
		}

		if uuid, ok := rowMap["uuid"].(string); ok {
			uuidSet[uuid] = struct{}{}
		}
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

// Background cleaner to purge leaked mod_rayo sessions
func startChannelSweeper(fs FSockClient) {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		resp, err := fs.SendApiCmd("show channels as json")
		if err != nil {
			continue
		}

		payload := make(map[string]any)
		if err := json.Unmarshal([]byte(resp), &payload); err != nil {
			continue
		}

		rawRows, ok := payload["rows"].([]any)
		if !ok {
			continue
		}

		for _, row := range rawRows {
			rowMap := row.(map[string]any)
			uuid, ok := rowMap["uuid"].(string)
			if !ok {
				continue
			}

			callState, _ := rowMap["callstate"].(string)

			// Kill orphaned legs sitting in DOWN state
			if callState == "DOWN" {
				log.Printf("[Sweeper] Clearing leaked Rayo session: %s", uuid)
				_, _ = fs.SendApiCmd("uuid_kill " + uuid)
			}
		}
	}
}

func customEventHandler(ctx context.Context, redisClient *redis.Client, eventStr string) {
	redisChannel, redisMsg, err := parseCustomEvent(eventStr)

	if err != nil {
		var appErr *AppError
		if errors.As(err, &appErr) && appErr.ErrorTracking {
			sentry.CaptureException(err)
		}

		fmt.Println("Error: " + err.Error())
		return
	}

	redisError := redisClient.Publish(ctx, redisChannel, redisMsg).Err()
	if redisError != nil {
		sentry.CaptureException(redisError)
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
	initSentry()
	defer sentry.Flush(2 * time.Second)

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

	startHealthServer(eventSocketClient, redisClient)

	// Heartbeat loop
	go callStatusUpdates(eventSocketClient, callPlatformClient)

	// Background channel cleaner for leaked mod_rayo sessions
	go startChannelSweeper(eventSocketClient)

	<-errChan
}
