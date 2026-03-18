#!/bin/sh

set -e

create_load_balancer_entry () {
  gateway_identifier="$1"
  port="$2"
  group_id="$3"
  group_id="${group_id:=1}"
  host="$4"
  host="${host:=freeswitch}"
  psql -q $DATABASE_URL \
  -c "INSERT INTO load_balancer (group_id, dst_uri, resources, probe_mode) VALUES('$group_id', 'sip:$host:$port', '$gateway_identifier=fs://:secret@freeswitch:8021', 2);"
}

assert_in_file () {
  filename="$1"
  test_string="$2"

  file=$(find . -type f -iname $(basename "$filename"))

  if ! grep -q "$test_string" $file; then
    cat <<-EOT
		Error:
		Expected $test_string to be found in $file but was not:
		`cat $file`
		EOT

    return 1
  fi
}

assert_not_in_file () {
  filename="$1"
  test_string="$2"

  file=$(find . -type f -iname $(basename "$filename"))

  if grep -q "$test_string" $file; then
    cat <<-EOT
		Error:
		Expected $test_string not to be found in $file but was found:
		`cat $file`
		EOT

    return 1
  fi
}

reset_rating_engine_data() {
  local db="$RATING_ENGINE_STORDB_DBNAME"
  local user="$DATABASE_USERNAME"
  local host="$DATABASE_HOST"
  local redis_url="$RATING_ENGINE_DATADB_REDIS_URL"
  local keep_redis_keys="versions cfi_cgrates.org"
  local keep_redis_keys_pattern=$(echo "$keep_redis_keys" | sed 's/ /|/g')

  # flush all redis keys except from whitelist
  redis-cli -u "$redis_url" --scan | grep -Ev "$keep_redis_keys_pattern" | while read key; do
    redis-cli -u "$redis_url" DEL "$key" > /dev/null
  done

  # Get all table names except "versions"
  tables=$(psql -h "$host" -U "$user" -d "$db" -Atc \
      "SELECT string_agg(tablename, ', ')
      FROM pg_tables
      WHERE schemaname='public' AND tablename <> 'versions';")

  if [ -z "$tables" ]; then
    echo "No tables found in $db"
    return 1
  fi

  # Truncate all tables in a single command (faster + handles FKs)
  psql -q -h "$host" -U "$user" -d "$db" -c "TRUNCATE TABLE $tables RESTART IDENTITY CASCADE;"

  # Clear the cache
  rating_engine_clear_cache
}

rating_engine_clear_cache () {
  rating_engine_api "CacheSv1.Clear" "[]"
}

rating_engine_create_default_charger () {
  local tenant="${1:-"TEST"}"
  local id="${2:-"TEST"}"

  rating_engine_api "APIerSv1.SetChargerProfile" "[
    {
      \"Tenant\": \"${tenant}\",
      \"ID\": \"${id}\",
      \"FilterIDs\": [],
      \"AttributeIDs\": [\"*none\"],
      \"RunID\": \"default\",
      \"Weight\": 0
    }
  ]"
}

rating_engine_create_destination () {
  local tpid="${1:-"TEST"}"
  local id="${2:-"TEST_CATCHALL"}"

  rating_engine_api "APIerSv2.SetTPDestination" "[
    {
      \"TPid\": \"$tpid\",
      \"ID\": \"$id\",
      \"Prefixes\": [\"0\",\"1\",\"2\",\"3\",\"4\",\"5\",\"6\",\"7\",\"8\",\"9\"]
    }
  ]"
}

rating_engine_create_rate () {
  local tpid="${1:-"TEST"}"
  local id="${2:-"TEST_CATCHALL"}"
  local rate_unit="${3:-"60s"}"
  local rate="${4:-100}"
  local rate_increment="${5:-"60s"}"

  rating_engine_api "APIerSv1.SetTPRate" "[
    {
      \"TPid\": \"$tpid\",
      \"ID\": \"$id\",
      \"RateSlots\": [
        {
          \"RateUnit\": \"${rate_unit}\",
          \"GroupIntervalStart\": null,
          \"RateIncrement\": \"${rate_increment}\",
          \"Rate\": $rate,
          \"ConnectFee\": 0.0
        }
      ]
    }
  ]"
}

rating_engine_create_destination_rate () {
  local tpid="${1:-"TEST"}"
  local id="${2:-"TEST_CATCHALL"}"
  local destination_id="${3:-"TEST_CATCHALL"}"
  local rate_id="${4:-"TEST_CATCHALL"}"

  rating_engine_api "APIerSv1.SetTPDestinationRate" "[
    {
      \"TPid\": \"$tpid\",
      \"ID\": \"$id\",
      \"DestinationRates\": [
        {
          \"RoundingDecimals\": 4,
          \"RateId\": \"$rate_id\",
          \"MaxCost\": 0,
          \"MaxCostStrategy\": null,
          \"DestinationId\": \"$destination_id\",
          \"RoundingMethod\": \"*up\"
        }
      ]
    }
  ]"
}

rating_engine_create_rating_plan () {
  local tpid="${1:-"TEST"}"
  local id="${2:-"TEST_CATCHALL"}"
  local destination_rates_id="${3:-"TEST_CATCHALL"}"

  rating_engine_api "APIerSv1.SetTPRatingPlan" "[
    {
      \"TPid\": \"$tpid\",
      \"ID\": \"$id\",
      \"RatingPlanBindings\": [
        {
          \"TimingId\": \"*any\",
          \"Weight\": 10,
          \"DestinationRatesId\": \"$destination_rates_id\"
        }
      ]
    }
  ]"
}

rating_engine_create_rating_profile () {
  local tpid="${1:-"TEST"}"
  local tenant="${2:-"TEST"}"
  local category="${3:-"outbound_calls"}"
  local rating_plan_id="${4:-"TEST_CATCHALL"}"
  local subject="${5:-"*any"}"
  local load_id="${6:-"somleng.org"}"

  rating_engine_api "APIerSv1.SetTPRatingProfile" "[
    {
      \"RatingPlanActivations\": [
        {
          \"RatingPlanId\": \"$rating_plan_id\",
          \"FallbackSubjects\": null,
          \"ActivationTime\": null
        }
      ],
      \"LoadId\": \"$load_id\",
      \"Category\": \"$category\",
      \"TPid\": \"$tpid\",
      \"Tenant\": \"$tenant\",
      \"Subject\": \"$subject\"
    }
  ]"
}

rating_engine_load_tariff_plan () {
  local tpid="${1:-"TEST"}"

  rating_engine_api "APIerSv1.LoadTariffPlanFromStorDb" "[
    {
      \"TPid\": \"$tpid\",
      \"DryRun\": false,
      \"Validate\": true
    }
  ]"
}

rating_engine_create_account () {
  local tenant="${1:-"TEST"}"
  local account="${2:-"sample-account-sid"}"

  rating_engine_api "APIerSv1.SetAccount" "[
    {
      \"Account\": \"$account\",
      \"Tenant\": \"$tenant\"
    }
  ]"
}

rating_engine_set_balance () {
  local tenant="${1:-"TEST"}"
  local account="${2:-"sample-account-sid"}"
  local balance="${3:-"500"}"

  rating_engine_api "APIerSv1.SetBalance" "[
    {
      \"Balance\": {
        \"ID\": \"$account\",
        \"Weight\": 10,
        \"Blocker\": true
      },
      \"Account\": \"$account\",
      \"Tenant\": \"$tenant\",
      \"BalanceType\": \"*monetary\",
      \"Value\": $balance
    }
  ]"
}

rating_engine_get_account () {
  local tenant="${1:-"TEST"}"
  local account="${2:-"sample-account-sid"}"

  response=$(rating_engine_api "APIerSv2.GetAccount" "[
    {
      \"Account\": \"$account\",
      \"Tenant\": \"$tenant\"
    }
  ]" "true")

  echo "$response"
}

rating_engine_get_cdrs () {
  response=$(rating_engine_api "APIerSv2.GetCDRs" "[]" "true")

  echo "$response"
}

rating_engine_api () {
  local method="$1"
  local params="$2"
  local verbose="${3:-false}"

  response=$(
    curl -s -X POST "http://rating-engine:$RATING_ENGINE_HTTP_PORT/jsonrpc" \
      -H "Content-Type: application/json" \
      -u "$RATING_ENGINE_HTTP_USER:$RATING_ENGINE_HTTP_PASSWORD" \
      -d "{
        \"jsonrpc\": \"2.0\",
        \"id\": 1,
        \"method\": \"$method\",
        \"params\": $params
      }"
  )

  error=$(echo "$response" | jq -r '.error')

  if [ "$error" != "null" ]; then
    echo "Error in response: $error" >&2
    return 1
  fi

  if [ "$verbose" = "true" ]; then
    echo "$response"
  fi
}

start_sipp_server () {
  local scenario="$1"
  local contact_ip="${2:-$(hostname -i)}"
  local scenario_name=$(basename "$scenario" .xml)

  clear_sipp_log_file "$scenario"

  pkill sipp || true
  sipp -sf "$scenario" -key contact_ip "$contact_ip" -trace_msg > /dev/null 2>&1 &
  echo $!
}

clear_sipp_log_file () {
  local scenario_name="$1"

  rm -rf "${scenario_name}"_*_messages.log
}

find_sipp_log_file () {
  local scenario="$1"
  local scenario_name=$(basename "$scenario" .xml)

  find . -type f -iname "${scenario_name}"_*_messages.log
}
