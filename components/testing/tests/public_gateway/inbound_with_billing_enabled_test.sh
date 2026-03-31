#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/smart_inbound.xml

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

if ! rating_engine_load_tariff_plan "$CARRIER_SID"; then
  echo "Failed to load tariff plan. Exiting."
  exit 1
fi

if ! rating_engine_create_rating_profile "$CARRIER_SID" "$CARRIER_SID" "inbound_calls" "TEST_CATCHALL" "$ACCOUNT_SID"; then
  echo "Failed to create rating profile. Exiting."
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

clear_sipp_log_file "$scenario"
sipp -sf $scenario public_gateway:5060 -s 3333 -m 1 -trace_msg > /dev/null

account_response=$(rating_engine_get_account "$CARRIER_SID" "$ACCOUNT_SID")
account_balance=$(echo "$account_response" | jq -r '.result.BalanceMap["*monetary"][0].Value')
if [ "$account_balance" != "493" ]; then
  echo "Account balance is ${account_balance}"
  exit 1
fi

sleep 1

cdrs_response=$(rating_engine_get_cdrs)
cdr_call_sid=$(echo "$cdrs_response" | jq -r '.result[0].ExtraFields["variable_sip_rh_X-Somleng-CallSid"]')
if [ -z "$cdr_call_sid" ] || [ "$cdr_call_sid" = "null" ]; then
  echo "CDR: ${cdrs_response}"
  exit 1
fi

cdr_call_sid=$(echo "$cdrs_response" | jq -r '.result[0].ExtraFields["variable_somleng_call_sid"]')
if [ -z "$cdr_call_sid" ] || [ "$cdr_call_sid" = "null" ]; then
  echo "CDR: ${cdrs_response}"
  exit 1
fi

# Update Rate

if ! rating_engine_create_rate "$CARRIER_SID" "TEST_CATCHALL" "60s" 5 "60s"; then
  echo "Failed to create rate. Exiting."
  exit 1
fi

if ! rating_engine_load_tariff_plan "$CARRIER_SID"; then
  echo "Failed to load tariff plan. Exiting."
  exit 1
fi

clear_sipp_log_file "$scenario"
sipp -sf $scenario public_gateway:5060 -s 3333 -m 1 -trace_msg > /dev/null

account_response=$(rating_engine_get_account "$CARRIER_SID" "$ACCOUNT_SID")
account_balance=$(echo "$account_response" | jq -r '.result.BalanceMap["*monetary"][0].Value')
if [ "$account_balance" != "488" ]; then
  echo "Account balance is ${account_balance}"
  exit 1
fi

# Update Rating Plan

if ! rating_engine_create_destination "$CARRIER_SID" "TEST_PROMO" "3333"; then
  echo "Failed to create destination. Exiting."
  exit 1
fi

if ! rating_engine_create_rate "$CARRIER_SID" "TEST_PROMO" "60s" 4 "60s"; then
  echo "Failed to create rate. Exiting."
  exit 1
fi

if ! rating_engine_create_destination_rate "$CARRIER_SID" "TEST_PROMO" "TEST_PROMO" "TEST_PROMO"; then
  echo "Failed to create destination rate. Exiting."
  exit 1
fi

if ! rating_engine_create_rating_plan "$CARRIER_SID" "TEST_CATCHALL" "TEST_PROMO,TEST_CATCHALL"; then
  echo "Failed to create rating plan. Exiting."
  exit 1
fi

if ! rating_engine_load_tariff_plan "$CARRIER_SID"; then
  echo "Failed to load tariff plan. Exiting."
  exit 1
fi

clear_sipp_log_file "$scenario"
sipp -sf $scenario public_gateway:5060 -s 3333 -m 1 -trace_msg > /dev/null

account_response=$(rating_engine_get_account "$CARRIER_SID" "$ACCOUNT_SID")
account_balance=$(echo "$account_response" | jq -r '.result.BalanceMap["*monetary"][0].Value')
if [ "$account_balance" != "484" ]; then
  echo "Account balance is ${account_balance}"
  exit 1
fi

# Remove Rating Profile

if ! rating_engine_remove_rating_profile "$CARRIER_SID" "$CARRIER_SID" "inbound_calls" "$ACCOUNT_SID"; then
  echo "Failed to remove tariff profile. Exiting."
  exit 1
fi

scenario=$current_dir/../../scenarios/inbound_forbidden.xml

clear_sipp_log_file "$scenario"
sipp -sf $scenario public_gateway:5060 -s 3333 -m 1 -trace_msg > /dev/null

log_file=$(find_sipp_log_file $scenario)

if ! assert_in_file "$log_file" "403 Forbidden"; then
	exit 1
fi

account_response=$(rating_engine_get_account "$CARRIER_SID" "$ACCOUNT_SID")
account_balance=$(echo "$account_response" | jq -r '.result.BalanceMap["*monetary"][0].Value')
if [ "$account_balance" != "484" ]; then
  echo "Account balance is ${account_balance}"
  exit 1
fi

# Add Rating Profile

if ! rating_engine_create_rating_profile "$CARRIER_SID" "$CARRIER_SID" "inbound_calls" "TEST_CATCHALL" "$ACCOUNT_SID"; then
  echo "Failed to create rating profile. Exiting."
  exit 1
fi

scenario=$current_dir/../../scenarios/smart_inbound.xml

sipp -sf $scenario public_gateway:5060 -s 3333 -m 1 -trace_msg > /dev/null

account_response=$(rating_engine_get_account "$CARRIER_SID" "$ACCOUNT_SID")
account_balance=$(echo "$account_response" | jq -r '.result.BalanceMap["*monetary"][0].Value')
if [ "$account_balance" != "480" ]; then
  echo "Account balance is ${account_balance}"
  exit 1
fi
