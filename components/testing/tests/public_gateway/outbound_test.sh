#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/uas.xml
sipp_pid=$(start_sipp_server $scenario)

cleanup() {
  kill "$sipp_pid" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

cdr_server_log="cdr-server.log"
cat /dev/null > $cdr_server_log

uas="$(hostname -i)"
media_server="$(dig +short freeswitch)"

curl -s -o /dev/null -XPOST -u "adhearsion:password" http://switch-app:8080/calls \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "to": "+85512334667",
  "from": "2442",
  "voice_url": "https://demo.twilio.com/welcome/",
  "voice_method": "GET",
  "sid": "sample-call-sid",
  "carrier_sid": "sample-carrier-sid",
  "account_sid": "sample-account-sid",
  "account_auth_token": "sample-auth-token",
  "direction": "outbound-api",
  "api_version": "2010-04-01",
  "default_tts_voice": "Basic.Kal",
  "call_direction": "outbound",
  "routing_parameters": {
    "address": null,
    "destination": "85512334667",
    "dial_string_prefix": null,
    "plus_prefix": false,
    "national_dialing": false,
    "host": "$uas",
    "username": null,
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

log_file=$(find_sipp_log_file $scenario)
if ! assert_in_file $log_file "c=IN IP4 $media_server"; then
	exit 1
fi

# Checks that FreeSWITCH sets an empty rport
if ! assert_in_file $log_file "rport;"; then
	exit 1
fi

if ! assert_in_file $log_file "X-Somleng-CallSid"; then
  exit 1
fi

if ! assert_not_in_file $log_file "X-Somleng-AccountSid"; then
  exit 1
fi

convert_base64_logs "$cdr_server_log" "decoded_cdr_server.log"

if ! assert_in_file "decoded_cdr_server.log" "\"record_cdr\":\"true\"" 1; then
  exit 1
fi
