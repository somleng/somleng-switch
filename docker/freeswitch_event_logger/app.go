package main

import (
	"encoding/json"
	"fmt"
	"log/syslog"
	"os"
	"time"

	"github.com/cgrates/fsock"
)

// Formats the event as map and prints it out
func logHeartbeat(eventStr string, connIdx int) {
	// Format the event from string into Go's map type
	eventMap := fsock.FSEventStrToMap(eventStr, []string{})
	jsonString, _ := json.Marshal(eventMap)
	fmt.Println(string(jsonString))
}

func main() {
	logger, errLog := syslog.New(syslog.LOG_INFO, "TestFSock")
	if errLog != nil {
		logger.Crit(fmt.Sprintf("Cannot connect to syslog:", errLog))
		return
	}

	// Filters
	evFilters := make(map[string][]string)
	evFilters["Event-Name"] = append(evFilters["Event-Name"], "HEARTBEAT")

	evHandlers := map[string][]func(string, int){
		"HEARTBEAT": {logHeartbeat},
	}

	event_socket_host := os.Getenv("EVENT_SOCKET_HOST")
	event_socket_password := os.Getenv("EVENT_SOCKET_PASSWORD")

	fs, err := fsock.NewFSock(event_socket_host, event_socket_password, 10, 0, fibDuration, evHandlers, evFilters, logger, 0, false)
	if err != nil {
		logger.Crit(fmt.Sprintf("FreeSWITCH error:", err))
		return
	}
	fs.ReadEvents()
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
