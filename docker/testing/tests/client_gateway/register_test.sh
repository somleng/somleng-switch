#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/register.xml

reset_db
create_subscriber_entry "user1" "password" "somleng.org"

sipp -sf $scenario client_gateway:5060 -key username "user1" -au "user1" -ap "password" -m 1 -trace_msg > /dev/null

reset_db
