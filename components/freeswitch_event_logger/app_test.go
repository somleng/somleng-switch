package main

import (
	"testing"
)

func TestParseEventFail(t *testing.T) {
	_, _, e := processIncomingEvent("")
	if e == nil {
		t.Errorf("got pass expected error")
	}
}

func TestParseEvent(t *testing.T) {
	incomingMsg :=
		`Event-Subclass: mod_twilio_stream%3A%3Adisconnect
Event-Name: CUSTOM
Core-UUID: 972157ac-e4e8-41b5-bd8b-26e904729226
Event-Payload: %7B%22event%22%3A%20%22disconnect%22,%22accountSid%22%3A%20%22c4612957-a00a-480d-a168-c75fbf29b2db%22,%22callSid%22%3A%20%2221fb5eee-ce7c-4e30-a069-439fa0269aeb%22,%22streamSid%22%3A%20%225cc24afd-ea42-4605-858d-5c47b597b646%22%7D`

	wantRedisChannel := `mod_twilio_stream:5cc24afd-ea42-4605-858d-5c47b597b646`
	wantRedisMsg := `{"event": "disconnect","accountSid": "c4612957-a00a-480d-a168-c75fbf29b2db","callSid": "21fb5eee-ce7c-4e30-a069-439fa0269aeb","streamSid": "5cc24afd-ea42-4605-858d-5c47b597b646"}`

	redisChannel, redisMsg, e := processIncomingEvent(incomingMsg)

	if e != nil {
		t.Errorf("Unexpected error")
	}

	if redisChannel != wantRedisChannel {
		t.Errorf("Unexpected redis channel expected %q got %q ", wantRedisChannel, redisChannel)
	}

	if redisMsg != wantRedisMsg {
		t.Errorf("Unexpected redis message expected %q got %q", wantRedisMsg, redisMsg)
	}
}
