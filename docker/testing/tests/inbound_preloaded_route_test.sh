#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/metfone_inbound.xml
source $current_dir/support/test_helpers.sh

reset_db
create_load_balancer_entry "gw" "5060"
create_address_entry $(hostname -i)
reload_opensips_tables

rm -f metfone_inbound_*_messages.log
sipp -sf $scenario opensips:5060 -s 1294 -m 1 > /dev/null

reset_db
