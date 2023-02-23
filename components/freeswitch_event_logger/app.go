package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/cgrates/fsock"
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
	// Filters
	evFilters := make(map[string][]string)
	evFilters["Event-Name"] = append(evFilters["Event-Name"], "HEARTBEAT")
	evFilters["Event-Name"] = append(evFilters["Event-Name"], "CUSTOM")

	evHandlers := map[string][]func(string, int){
		"HEARTBEAT": {logHeartbeat},
		"CUSTOM":    {logHeartbeat},
	}

	event_socket_host := os.Getenv("EVENT_SOCKET_HOST")
	event_socket_password := os.Getenv("EVENT_SOCKET_PASSWORD")

	fs, err := fsock.NewFSock(event_socket_host, event_socket_password, 10, 0, fibDuration, evHandlers, evFilters, nopLogger{}, 0, false)
	if err != nil {
		fmt.Println(fmt.Sprintf("FreeSWITCH error: %s", err))
		return
	}
	fs.ReadEvents()
}
