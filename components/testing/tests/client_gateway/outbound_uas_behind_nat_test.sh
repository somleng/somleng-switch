#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

log_file=$(find . -type f -iname "uas_*_messages.log")
cat /dev/null > $log_file

reset_db
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
  "account_sid": "sample-account-sid",
  "account_auth_token": "sample-auth-token",
  "direction": "outbound-api",
  "api_version": "2010-04-01",
  "default_tts_voice": "Basic.Kal",
  "routing_parameters": {
    "destination": "85512334667",
    "dial_string_prefix": null,
    "plus_prefix": true,
    "national_dialing": false,
    "host": null,
    "username": "user1",
    "symmetric_latching": true,
    "address": "+85512334667@$uas;fs_path=sip:$client_gateway:5060"
  },
  "test_headers": {
    "X-UAS-Contact-Ip": "100.65.107.153"
  }
}
EOF

sleep 10

reset_db

if ! assert_in_file $log_file "ACK sip:$uas"; then
  exit 1
fi

if ! assert_in_file $log_file "BYE sip:$uas"; then
  exit 1
fi
