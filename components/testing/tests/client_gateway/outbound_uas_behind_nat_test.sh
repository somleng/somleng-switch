#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/uas.xml
sipp_pid=$(start_sipp_server $scenario "100.65.107.153")

# ensure sipp is killed when script exits
cleanup() {
  kill "$sipp_pid" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

reset_opensips_db
create_rtpengine_entry "udp:media_proxy:2223"
reload_opensips_tables

uas="$(hostname -i)"
client_gateway="$(dig +short client_gateway)"

curl -s -o /dev/null -XPOST -u "adhearsion:password" http://switch-app:8080/calls \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "to": "+85512334667",
  "from": "2442",
  "voice_url": null,
  "voice_method": null,
  "twiml": "<Response><Say>Hello World!</Say><Hangup /></Response>",
  "sid": "sample-call-sid",
  "carrier_sid": "sample-carrier-sid",
  "account_sid": "sample-account-sid",
  "account_auth_token": "sample-auth-token",
  "direction": "outbound-api",
  "call_direction": "outbound",
  "api_version": "2010-04-01",
  "default_tts_voice": "Basic.Kal",
  "routing_parameters": {
    "address": null,
    "destination": "85512334667",
    "dial_string_prefix": null,
    "plus_prefix": true,
    "national_dialing": false,
    "host": null,
    "username": "user1",
    "sip_profile": "nat_gateway"
  },
  "billing_parameters": {
    "enabled": false,
    "billing_mode": "prepaid",
    "category": "outbound_calls"
  }
}
EOF

sleep 10

reset_opensips_db

log_file=$(find_sipp_log_file $scenario)
if ! assert_in_file $log_file "ACK sip:$uas"; then
  exit 1
fi

if ! assert_in_file $log_file "BYE sip:$uas"; then
  exit 1
fi
