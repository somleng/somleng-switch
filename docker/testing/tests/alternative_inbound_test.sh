#!/bin/sh

set -e

echo "Running: `basename $0`"

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/zamtel_inbound.xml
source $current_dir/support/support.sh

reset_db
create_load_balancer_entry "gwalt" "5080"
create_address_entry $(hostname -i)
reload_opensips_tables

rm -f zamtel_inbound_*_messages.log
sipp -sf $scenario opensips:5080 -s 7888 -m 1 -trace_msg > /dev/null
log_file=$(find . -type f -iname "zamtel_inbound_*_messages.log")

test_string="c=IN IP4 18.141.245.230" # EXT_RTP_IP

if ! grep -q "$test_string" $log_file; then
  cat <<-EOT
	Error:
	$test_string not found in:
	`cat $log_file`
	EOT
  exit 1
fi

reset_db
