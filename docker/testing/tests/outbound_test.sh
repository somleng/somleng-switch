#!/bin/sh

set -e

echo "Running: `basename $0`"

log_file=$(find . -type f -iname "uas_*_messages.log")
cat /dev/null > $log_file

curl -s -o /dev/null -XPOST -u "adhearsion:password" http://somleng-switch:8080/calls \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "to": "+85512334667",
  "from": "2442",
  "voice_url": "https://demo.twilio.com/welcome/",
  "voice_method": "GET",
  "sid": "sample-call-sid",
  "account_sid": "sample-account-sid",
  "account_auth_token": "sample-auth-token",
  "direction": "outbound-api",
  "api_version": "2010-04-01",
  "routing_instructions": {
    "dial_string": "85512334667@testing",
    "nat_supported": true
  }
}
EOF

sleep 10

test_string="c=IN IP4 13.250.230.15" # EXT_RTP_IP

if ! grep -q "$test_string" $log_file; then
  cat <<-EOT
	Error:
	$test_string not found in:
	`cat $log_file`
	EOT
  exit 1
fi
