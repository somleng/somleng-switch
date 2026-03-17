#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/smart_inbound.xml

uas_scenario=$current_dir/../../scenarios/uas.xml
sipp_pid=$(start_sipp_server $uas_scenario)

# ensure sipp is killed when script exits
cleanup() {
  kill "$sipp_pid" 2>/dev/null || true
}

log_file="smart_inbound_*_messages.log"
rm -f $log_file

media_server="$(dig +short freeswitch)"
public_gateway="$(dig +short public_gateway)"

reset_opensips_db
create_load_balancer_entry "gw" "5060" "2"
create_address_entry "$(hostname -i)" "2"
reload_opensips_tables

reset_rating_engine_data

if ! rating_engine_create_default_charger "$CARRIER_SID" "$CARRIER_SID"; then
  echo "Failed to create default charger profile. Exiting."
  exit 1
fi

if ! rating_engine_create_destination "$CARRIER_SID" "TEST_CATCHALL"; then
  echo "Failed to create destination. Exiting."
  exit 1
fi

if ! rating_engine_create_rate "$CARRIER_SID" "TEST_CATCHALL" "60s" 7 "60s"; then
  echo "Failed to create rate. Exiting."
  exit 1
fi

if ! rating_engine_create_destination_rate "$CARRIER_SID" "TEST_CATCHALL" "TEST_CATCHALL" "TEST_CATCHALL"; then
  echo "Failed to create destination rate. Exiting."
  exit 1
fi

if ! rating_engine_create_rating_plan "$CARRIER_SID" "TEST_CATCHALL" "TEST_CATCHALL"; then
  echo "Failed to create rating plan. Exiting."
  exit 1
fi

if ! rating_engine_create_rating_profile "$CARRIER_SID" "$CARRIER_SID" "inbound_calls" "TEST_CATCHALL" "$ACCOUNT_SID"; then
  echo "Failed to create rating profile. Exiting."
  exit 1
fi

if ! rating_engine_load_tariff_plan "$CARRIER_SID"; then
  echo "Failed to load tariff plan. Exiting."
  exit 1
fi

if ! rating_engine_create_account "$CARRIER_SID" "$ACCOUNT_SID"; then
  echo "Failed to create account. Exiting."
  exit 1
fi

if ! rating_engine_set_balance "$CARRIER_SID" "$ACCOUNT_SID" "500"; then
  echo "Failed to set balance. Exiting."
  exit 1
fi

sipp -sf $scenario public_gateway:5060 -s 5555 -m 1 -trace_msg > /dev/null

reset_opensips_db

account_response=$(rating_engine_get_account "$CARRIER_SID" "$ACCOUNT_SID")
account_balance=$(echo "$account_response" | jq -r '.result.BalanceMap["*monetary"][0].Value')
if [ "$account_balance" != "493" ]; then
  echo "Account balance is ${account_balance}"
  exit 1
fi

cdrs_response=$(rating_engine_get_cdrs)
cdr_call_sid=$(echo "$cdrs_response" | jq -r '.result[0].ExtraFields["variable_sip_rh_X-Somleng-CallSid"]')
if [ -z "$cdr_call_sid" ] || [ "$cdr_call_sid" = "null" ]; then
  echo "CDR: ${cdrs_response}"
  exit 1
fi
