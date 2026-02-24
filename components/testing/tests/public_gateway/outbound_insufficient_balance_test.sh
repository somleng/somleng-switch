#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

log_file=$(find . -type f -iname "uas_*_messages.log")
cdr_server_log="cdr-server.log"
cat /dev/null > $log_file
cat /dev/null > $cdr_server_log

uas="$(hostname -i)"
media_server="$(dig +short freeswitch)"

carrier_sid="c0591700-69c6-465c-9353-7c98ec93cdc0"
account_sid="a7570e4c-4f43-4a15-a47b-96247ba02ceb"
call_sid="93943b68-2fa0-449f-993d-7c83a4c462e1"
destination="85512334667"

reset_rating_engine_data

if ! rating_engine_create_default_charger "$carrier_sid" "$carrier_sid"; then
  echo "Failed to create default charger profile. Exiting."
  exit 1
fi

if ! rating_engine_create_destination "$carrier_sid" "TEST_CATCHALL"; then
  echo "Failed to create destination. Exiting."
  exit 1
fi

if ! rating_engine_create_rate "$carrier_sid" "TEST_CATCHALL" "60s" 7 "60s"; then
  echo "Failed to create rate. Exiting."
  exit 1
fi

if ! rating_engine_create_destination_rate "$carrier_sid" "TEST_CATCHALL" "TEST_CATCHALL" "TEST_CATCHALL"; then
  echo "Failed to create destination rate. Exiting."
  exit 1
fi

if ! rating_engine_create_rating_plan "$carrier_sid" "TEST_CATCHALL" "TEST_CATCHALL"; then
  echo "Failed to create rating plan. Exiting."
  exit 1
fi

if ! rating_engine_create_rating_profile "$carrier_sid" "$carrier_sid" "outbound_calls" "TEST_CATCHALL" "$account_sid"; then
  echo "Failed to create rating profile. Exiting."
  exit 1
fi

if ! rating_engine_load_tariff_plan "$carrier_sid"; then
  echo "Failed to load tariff plan. Exiting."
  exit 1
fi

if ! rating_engine_create_account "$carrier_sid" "$account_sid"; then
  echo "Failed to create account. Exiting."
  exit 1
fi

if ! rating_engine_set_balance "$carrier_sid" "$account_sid" "5"; then
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
  "account_sid": "$account_sid",
  "carrier_sid": "$carrier_sid",
  "account_auth_token": "sample-auth-token",
  "direction": "outbound-api",
  "api_version": "2010-04-01",
  "default_tts_voice": "Basic.Kal",
  "call_direction": "outbound",
  "routing_parameters": {
    "address": null,
    "destination": "$destination",
    "dial_string_prefix": null,
    "plus_prefix": false,
    "national_dialing": false,
    "host": "$uas",
    "username": null,
    "sip_profile": "nat_gateway"
  },
  "billing_parameters": {
    "enabled": true,
    "billing_mode": "prepaid",
    "category": "outbound_calls"
  },
  "test_headers": {
    "X-UAS-Contact-Ip": "$uas"
  }
}
EOF
)

sleep 10

if [ -s "$log_file" ]; then
	exit 1
fi

if ! assert_in_file $cdr_server_log "sip%3A403"; then
  exit 1
fi
