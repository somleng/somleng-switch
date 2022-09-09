#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/metfone_inbound.xml

reset_db
create_load_balancer_entry "gw" "5060"
create_address_entry $(hostname -i)
reload_opensips_tables

rm -f metfone_inbound_*_messages.log
sipp -sf $scenario public_gateway:5060 -s 1294 -m 1 -trace_msg > /dev/null

reset_db
