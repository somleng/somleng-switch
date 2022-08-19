#!/bin/sh

set -e

echo "Running: $(basename $0)"

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh

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
    "nat_supported": false
  }
}
EOF

sleep 10

if ! assert_in_file $log_file "c=IN IP4 18.141.245.230"; then
	exit 1
fi
