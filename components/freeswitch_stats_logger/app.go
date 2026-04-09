package main

import (
	"encoding/json"
	"fmt"
	"log/syslog"
	"os"
	"time"

	"github.com/cgrates/fsock"
)

func NewEventSocketClient(eventHandlers map[string][]func(string, int), eventFilters map[string][]string, errChan chan error) *fsock.FSock {
	event_socket_host := os.Getenv("EVENT_SOCKET_HOST")
	event_socket_password := os.Getenv("EVENT_SOCKET_PASSWORD")

	logger, errLog := syslog.New(syslog.LOG_INFO, "freeswitch_stats_logger")
	if errLog != nil {
		panic(errLog)
	}

	fs, err := fsock.NewFSock(event_socket_host, event_socket_password, 10, 60, 0, fibDuration, eventHandlers, eventFilters, logger, 0, false, errChan)
	if err != nil {
		fmt.Printf("FreeSWITCH error: %s\n", err)
		panic(err)
	}

	return fs
}

// Formats the event as map and prints it out
func logStats(eventStr string, connIdx int) {
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
	evFilters := map[string][]string{
		"Event-Name": {
			"HEARTBEAT",
		},
	}

	evHandlers := map[string][]func(string, int){
		"HEARTBEAT": {logStats},
	}

	errChan := make(chan error)
	NewEventSocketClient(evHandlers, evFilters, errChan)

	<-errChan
}
