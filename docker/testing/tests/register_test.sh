#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/register.xml
source $current_dir/support/test_helpers.sh

reset_db
create_subscriber_entry "user1" "password" "somleng.org"

sipp -sf $scenario registrar:5060 -key username "user1" -au "user1" -ap "password" -m 1 -trace_msg > /dev/null

reset_db
