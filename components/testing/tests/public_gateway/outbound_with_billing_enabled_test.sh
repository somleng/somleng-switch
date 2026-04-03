#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/uas.xml
sipp_pid=$(start_sipp_server $scenario)

# ensure sipp is killed when script exits
cleanup() {
  kill "$sipp_pid" 2>/dev/null || true
}

trap cleanup EXIT INT TERM


uas="$(hostname -i)"
media_server="$(dig +short freeswitch)"

call_sid="93943b68-2fa0-449f-993d-7c83a4c462e1"
destination="85512334667"

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

if ! rating_engine_create_rating_profile "$CARRIER_SID" "$CARRIER_SID" "outbound_calls" "TEST_CATCHALL" "$ACCOUNT_SID"; then
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

response=$(curl -s -XPOST -u "adhearsion:password" http://switch-app:8080/calls \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "to": "+$destination",
  "from": "2442",
  "voice_url": "https://demo.twilio.com/welcome/",
  "voice_method": "GET",
  "sid": "$call_sid",
  "account_sid": "$ACCOUNT_SID",
  "carrier_sid": "$CARRIER_SID",
  "account_auth_token": "sample-auth-token",
  "direction": "outbound-api",
  "api_version": "2010-04-01",
  "default_tts_voice": "Basic.Kal",
  "call_direction": "outbound",
  "routing_parameters": {
    "address": null,
    "destination": "$destination",
    "dial_string_prefix": null,
    "plus_prefix": true,
    "national_dialing": false,
    "host": "$uas",
    "username": null,
    "sip_profile": "nat_gateway"
  },
  "billing_parameters": {
    "enabled": true,
    "billing_mode": "prepaid",
    "category": "outbound_calls"
  }
}
EOF
)

sleep 10

log_file=$(find_sipp_log_file $scenario)
if ! assert_in_file $log_file "INVITE sip:+$destination@$uas"; then
	exit 1
fi

if ! assert_in_file $log_file "X-Somleng-CallSid"; then
  exit 1
fi

if ! assert_not_in_file $log_file "X-Somleng-AccountSid"; then
  exit 1
fi

account_response=$(rating_engine_get_account "$CARRIER_SID" "$ACCOUNT_SID")
account_balance=$(echo "$account_response" | jq -r '.result.BalanceMap["*monetary"][0].Value')
if [ "$account_balance" != "493" ]; then
  echo "Account balance is ${account_balance}"
  exit 1
fi

cdrs_response=$(rating_engine_get_cdrs)
cdr_call_sid=$(echo "$cdrs_response" | jq -r '.result[0].ExtraFields["variable_sip_h_X-Somleng-CallSid"]')
if [ "$cdr_call_sid" != "$call_sid" ]; then
  echo "CDR call sid is ${cdr_call_sid}"
  exit 1
fi
