#!/bin/sh

set -e

echo "Running: `basename $0`"

curl -XPOST -u "adhearsion:password" -d @/fixtures/calls.json somleng-switch:8080/calls

sleep 10

test_string="c=IN IP4 13.250.230.15" # EXT_RTP_IP

if ! grep -q "$test_string" uas_*_messages.log; then
  cat <<-EOT
	Error:
	$test_string not found in:
	`cat uas_*_messages.log`
	EOT
  exit 1
fi
