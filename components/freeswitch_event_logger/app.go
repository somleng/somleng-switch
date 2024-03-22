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

const EVENT_DISCONNECT = "mod_twilio_stream::disconnect"
const EVENT_ERROR = "mod_twilio_stream::error"
const EVENT_CONNECT_SUCCESS = "mod_twilio_stream::connect"
const EVENT_START = "mod_twilio_stream::start"
const EVENT_STOP = "mod_twilio_stream::stop"
const EVENT_DTMF = "mod_twilio_stream::dtmf"
const EVENT_MARK = "mod_twilio_stream::mark"
const EVENT_SOCKET_MARK = "mod_twilio_stream::socket_mark"
const EVENT_SOCKET_CLEAR = "mod_twilio_stream::socket_clear"

// Formats the event as map and prints it out
func logHeartbeat(eventStr string, connIdx int) {
	// Format the event from string into Go's map type
	eventMap := fsock.FSEventStrToMap(eventStr, []string{})
	jsonString, _ := json.Marshal(eventMap)
	fmt.Println(string(jsonString))
}

func customEventHandler(eventStr string, connIdx int) {
	eventMap := fsock.FSEventStrToMap(eventStr, []string{})
	jsonString, _ := json.Marshal(eventMap)
	fmt.Println("Receiving custom Event")
	fmt.Println(string(jsonString))

	// 1. Get the Event-Subclass
	// 2. Get the Event-Payload
	// 3. Get the stream_sid
	// 4. Split the event-subclass on the :: to get the module name
	// 5. Combine the module name with the stream-sid (mod_twilio_stream::stream-sid)
	// 6. Publish the Event-Payload to the channel from step 5

	// Handle the event
	// Closed event
	// {
	//   Event-Subclass: "mod_twilio_stream::closed",
	//   Event-Payload: {
	//     "event": "closed",
	//     "stream_sid": "stream-sid",
	//     "foo": "bar"
	//	 }
	// }

	// Start event
	// {
	//   Event-Subclass: "mod_twilio_stream::start",
	//   Event-Payload: {
	//     "event": "start",
	//     "stream_sid": "stream-sid",
	//     "tracks": ["inbound", "outbound"]
	//   }
	// }
	//

	switch eventMap["Event-Subclass"] {
	case EVENT_CONNECT_SUCCESS:
		fmt.Println("CONNECT")
	case EVENT_DISCONNECT:
		fmt.Println("DISCONNECT")
	default:
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
	evFilters := map[string][]string{
		"Event-Name": {"HEARTBEAT", "CUSTOM"},
	}
	evHandlers := map[string][]func(string, int){
		"HEARTBEAT": {logHeartbeat},
		"ALL":       {customEventHandler},
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
