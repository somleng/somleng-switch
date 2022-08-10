#!/bin/sh

set -e

echo "Running: `basename $0`"

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/zamtel_sip_options.xml
source $current_dir/support/support.sh

reset_db
create_address_entry $(hostname -i)
reload_opensips_tables

sipp -sf $scenario opensips:5080 -s 1234 -m 1 > /dev/null

reset_db
