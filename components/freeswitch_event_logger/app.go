package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
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

// Formats the event as map and prints it out
func logHeartbeat(eventStr string, connIdx int) {
	// Format the event from string into Go's map type
	eventMap := fsock.FSEventStrToMap(eventStr, []string{})
	jsonString, _ := json.Marshal(eventMap)
	fmt.Println(string(jsonString))
}

func customEventHandler(ctx context.Context, rdb *redis.Client, eventStr string) {
	eventMap := fsock.FSEventStrToMap(eventStr, []string{})

	modTwilioStreamPrefix := "mod_twilio_stream"
	eventName := eventMap["Event-Subclass"]

	if !strings.HasPrefix(eventName, modTwilioStreamPrefix) {
		fmt.Println("Unhandled Event Type: " + eventName)
		return
	}

	eventPayload := make(map[string]any)
	parsePayloadError := json.Unmarshal([]byte(eventMap["Event-Payload"]), &eventPayload)
	if parsePayloadError != nil {
		fmt.Println("Failed to parse Event Payload: " + eventMap["Event-Payload"])
		return
	}

	streamSid, streamSidExists := eventPayload["streamSid"].(string)
	if !streamSidExists {
		fmt.Println("Event does not contain streamSid: " + eventMap["Event-Payload"])
		return
	}

	fmt.Println("Publishing Event:" + eventMap["Event-Payload"])
	redisChannel := modTwilioStreamPrefix + ":" + streamSid
	redisError := rdb.Publish(ctx, redisChannel, eventMap["Event-Payload"]).Err()
	if redisError != nil {
		fmt.Println("Problem publishing to Redis channel: " + redisChannel + " Payload: " + eventMap["Event-Payload"] + " Error: " + redisError.Error())
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

	redis_url := os.Getenv("REDIS_URL")
	opt, e := redis.ParseURL(redis_url)
	if e != nil {
		panic(e)
	}

	rdb := redis.NewClient(opt)

	customEventHandlerWrapper := func(eventStr string, connIdx int) {
		customEventHandler(ctx, rdb, eventStr)
	}

	evFilters := map[string][]string{
		"Event-Name": {"HEARTBEAT", "CUSTOM"},
	}

	evHandlers := map[string][]func(string, int){
		"HEARTBEAT": {logHeartbeat},
		"ALL":       {customEventHandlerWrapper},
	}

	event_socket_host := os.Getenv("EVENT_SOCKET_HOST")
	event_socket_password := os.Getenv("EVENT_SOCKET_PASSWORD")

	errChan := make(chan error)
	_, err := fsock.NewFSock(event_socket_host, event_socket_password, 10, 60, 0, fibDuration, evHandlers, evFilters, nopLogger{}, 0, false, errChan)
	if err != nil {
		fmt.Printf("FreeSWITCH error: %s\n", err)
		return
	}
	<-errChan
}
