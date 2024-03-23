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

func customEventHandler(ctx context.Context, rdb *redis.Client, eventStr string, connIdx int) {
	eventMap := fsock.FSEventStrToMap(eventStr, []string{})
	jsonString, _ := json.Marshal(eventMap)
	fmt.Println("Receiving custom Event")
	fmt.Println(string(jsonString))

	prefix := "mod_twilio_stream"
	eventName := eventMap["Event-Subclass"]
	if strings.HasPrefix(eventName, prefix) {
		payload := eventMap["Event-Payload"]

		fmt.Println("--------START---------")
		fmt.Println(payload)
		fmt.Println("--------END---------")

		result := make(map[string]any)
		err := json.Unmarshal([]byte(payload), &result)
		if err != nil {
			panic(err)
		}

		stream_sid, stream_sid_ok := result["streamSid"].(string)
		fmt.Println("--------START---------")
		fmt.Println(result)
		fmt.Println(stream_sid)
		fmt.Println(stream_sid_ok)
		fmt.Println("--------END---------")

		if stream_sid_ok {
			fmt.Println(stream_sid)
			err := rdb.Publish(ctx, prefix+":"+stream_sid, payload).Err()
			if err != nil {
				panic(err)
			}
		} else {
			fmt.Println("Unable to process streamSid")
		}
	} else {
		fmt.Println("Unhandled Event Type:" + eventMap["Event-Subclass"])
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
		customEventHandler(ctx, rdb, eventStr, connIdx)
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
