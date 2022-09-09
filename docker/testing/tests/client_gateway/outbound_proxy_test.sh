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

sip_proxy="$(dig +short client_gateway)"
media_proxy="$(dig +short media_proxy)"

curl -s -o /dev/null -XPOST -u "adhearsion:password" http://somleng-switch:8080/calls \
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
  "routing_instructions": {
    "dial_string": "85512334667@testing;fs_path=sip:$sip_proxy:5060"
  }
}
EOF

sleep 10

reset_db

if ! assert_in_file $log_file "Record-Route: <sip:$sip_proxy:5060;lr;r2=on>"; then
	exit 1
fi

if ! assert_in_file $log_file "c=IN IP4 $media_proxy"; then
	exit 1
fi
