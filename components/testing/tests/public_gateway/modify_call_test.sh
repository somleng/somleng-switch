#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

log_file=$(find . -type f -iname "uas_*_messages.log")
cat /dev/null > $log_file

uas="$(hostname -i)"
media_server="$(dig +short freeswitch)"

output=$(curl -s -XPOST -u "adhearsion:password" http://switch-app:8080/calls \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "to": "+85512334667",
  "from": "2442",
  "voice_url": "https://demo.twilio.com/docs/voice.xml",
  "voice_method": "POST",
  "twiml": "<Response><Say>Hello how are you today? How is the weather?</Say></Response>",
  "sid": "sample-call-sid",
  "account_sid": "sample-account-sid",
  "account_auth_token": "sample-auth-token",
  "direction": "outbound-api",
  "api_version": "2010-04-01",
  "default_tts_voice": "Basic.Kal",
  "routing_parameters": {
    "destination": "85512334667",
    "dial_string_prefix": null,
    "plus_prefix": false,
    "national_dialing": false,
    "host": "$uas",
    "username": null,
    "symmetric_latching": true
  },
  "test_headers": {
    "X-UAS-Contact-Ip": "$uas"
  }
}
EOF
)

echo $output

call_id=$(echo $output | jq -r ".id")

echo $call_id

sleep 5

output=$(curl -s -XPATCH -u "adhearsion:password" http://switch-app:8080/calls/$call_id \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "voice_url": "https://demo.twilio.com/welcome/",
  "voice_method": "GET"
}
EOF
)

echo $output

sleep 10

if ! assert_in_file $log_file "c=IN IP4 $media_server"; then
	exit 1
fi

# Checks that FreeSWITCH sets an empty rport
if ! assert_in_file $log_file "rport;"; then
	exit 1
fi
