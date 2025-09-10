#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

uas="$(hostname -i)"
call_sid="$(cat /proc/sys/kernel/random/uuid)"

output=$(curl -s -XPOST -u "adhearsion:password" http://switch-app:$SWITCH_PORT/calls \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "to": "+85512334667",
  "from": "2442",
  "voice_url": null,
  "voice_method": null,
  "twiml": "<Response><Connect><Stream url=\"ws://$uas:$WS_SERVER_PORT\" /></Connect></Response>",
  "sid": "$call_sid",
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
    "sip_profile": "nat_gateway"
  },
  "test_headers": {
    "X-UAS-Contact-Ip": "$uas"
  }
}
EOF
)

call_id=$(echo $output | jq -r ".id")
host=$(echo $output | jq -r ".host")

sleep 5

curl -s -XPATCH -u "adhearsion:password" http://$host:$SWITCH_PORT/calls/$call_id \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "voice_url": "http://$uas:$FILE_SERVER_PORT/support/say.xml",
  "voice_method": "GET"
}
EOF

sleep 5

# Checks the call SID is included in the request to get the new TwiML
if ! assert_in_file $FILE_SERVER_LOG_FILE "$call_sid"; then
	exit 1
fi
