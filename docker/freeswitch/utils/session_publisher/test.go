package main

import (
	"fmt"
	"log/syslog"

	"github.com/cgrates/fsock"
)

// Formats the event as map and prints it out
func printHeartbeat(eventStr string, connIdx int) {
	// Format the event from string into Go's map type
	eventMap := fsock.FSEventStrToMap(eventStr, []string{})
	sessionCount := eventMap["Session-Count"]
	fmt.Printf("%v, connIdx: %d, sessionCount: %v\n", eventMap, connIdx, sessionCount)
}

func main() {
	// Init a syslog writter for our test
	l, errLog := syslog.New(syslog.LOG_INFO, "TestFSock")
	if errLog != nil {
		l.Crit(fmt.Sprintf("Cannot connect to syslog:", errLog))
		return
	}

	// Filters
	evFilters := make(map[string][]string)
	evFilters["Event-Name"] = append(evFilters["Event-Name"], "HEARTBEAT")

	// We are interested in heartbeats, channel_answer, channel_hangup define handler for them
	evHandlers := map[string][]func(string, int){
		"HEARTBEAT": {printHeartbeat},
	}

	fs, err := fsock.NewFSock("localhost:8021", "ClueCon", 10, evHandlers, evFilters, l, 0, false)
	if err != nil {
		l.Crit(fmt.Sprintf("FreeSWITCH error:", err))
		return
	}
	fs.ReadEvents()
}
