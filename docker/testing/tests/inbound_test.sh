#!/bin/sh

set -e

echo "Running: `basename $0`"

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/smart_inbound.xml

rm -f smart_inbound_*_messages.log

sipp -sf $scenario opensips:5060 -s 1234 -m 1 -trace_msg > /dev/null
log_file=$(find . -type f -iname "smart_inbound_*_messages.log")

test_string="c=IN IP4 13.250.230.15" # EXT_RTP_IP

if ! grep -q "$test_string" $log_file; then
  cat <<-EOT
	Error:
	$test_string not found in:
	`cat $log_file`
	EOT
  exit 1
fi
