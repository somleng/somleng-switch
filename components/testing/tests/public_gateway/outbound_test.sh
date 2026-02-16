#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

log_file=$(find . -type f -iname "uas_*_messages.log")
cdr_server_log="cdr-server.log"
cat /dev/null > $log_file
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
  },
  "test_headers": {
    "X-UAS-Contact-Ip": "$uas"
  }
}
EOF

sleep 10

if ! assert_in_file $log_file "c=IN IP4 $media_server"; then
	exit 1
fi

# Checks that FreeSWITCH sets an empty rport
if ! assert_in_file $log_file "rport;"; then
	exit 1
fi

if ! assert_in_file $cdr_server_log "proxy_leg"; then
  exit 1
fi
