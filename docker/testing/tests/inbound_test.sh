#!/bin/sh

set -e

echo "Running: `basename $0`"

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/smart_inbound.xml

sipp -sf $scenario opensips:5060 -s 1234 -m 1 -trace_msg > /dev/null

test_string="c=IN IP4 13.250.230.15" # EXT_RTP_IP

if ! grep -q "$test_string" smart_inbound_*_messages.log; then
  cat <<-EOT
	Error:
	$test_string not found in:
	`cat smart_inbound_*_messages.log`
	EOT
  exit 1
fi
