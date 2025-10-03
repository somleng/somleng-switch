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

reset_billing_engine_data() {
  local db="$BILLING_ENGINE_STORDB_DBNAME"
  local user="$DATABASE_USERNAME"
  local host="$DATABASE_HOST"
  local redis_url="$BILLING_ENGINE_DATADB_REDIS_URL"
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
}

billing_engine_set_charger_profile () {
  billing_engine_api "APIerSv1.SetChargerProfile" "[
    {
      \"ID\": \"CHARGER_Default\",
      \"FilterIDs\": [],
      \"AttributeIDs\": [\"*none\"],
      \"RunID\": \"default\",
      \"Weight\": 0
    }
  ]"
}

billing_engine_create_destination () {
  local prefix="${1:-""}"
  billing_engine_api "APIerSv2.SetTPDestination" "[
    {
      \"TPid\": \"TEST\",
      \"ID\": \"TEST_CATCHALL\",
      \"Prefixes\": [\"0\",\"1\",\"2\",\"3\",\"4\",\"5\",\"6\",\"7\",\"8\",\"9\"]
    }
  ]"
}

billing_engine_create_rate () {
  local rate_per_minute="${1:-100}"
  local rate_increment="${2:-"1s"}"
  billing_engine_api "APIerSv1.SetTPRate" "[
    {
      \"TPid\": \"TEST\",
      \"ID\": \"TEST_CATCHALL\",
      \"RateSlots\": [
        {
          \"RateUnit\": \"60s\",
          \"GroupIntervalStart\": null,
          \"RateIncrement\": \"${rate_increment}\",
          \"Rate\": $rate_per_minute,
          \"ConnectFee\": 0.0
        }
      ]
    }
  ]"
}

billing_engine_create_destination_rate () {
  billing_engine_api "APIerSv1.SetTPDestinationRate" "[
    {
      \"TPid\": \"TEST\",
      \"ID\": \"TEST_CATCHALL\",
      \"DestinationRates\": [
        {
          \"RoundingDecimals\": 4,
          \"RateId\": \"TEST_CATCHALL\",
          \"MaxCost\": 0,
          \"MaxCostStrategy\": null,
          \"DestinationId\": \"TEST_CATCHALL\",
          \"RoundingMethod\": \"*up\"
        }
      ]
    }
  ]"
}

billing_engine_create_rating_plan () {
  billing_engine_api "APIerSv1.SetTPRatingPlan" "[
    {
      \"TPid\": \"TEST\",
      \"ID\": \"TEST_CATCHALL\",
      \"RatingPlanBindings\": [
        {
          \"TimingId\": \"*any\",
          \"Weight\": 10,
          \"DestinationRatesId\": \"TEST_CATCHALL\"
        }
      ]
    }
  ]"
}

billing_engine_create_rating_profile () {
  billing_engine_api "APIerSv1.SetTPRatingProfile" "[
    {
      \"RatingPlanActivations\": [
        {
          \"RatingPlanId\": \"TEST_CATCHALL\",
          \"FallbackSubjects\": null,
          \"ActivationTime\": null
        }
      ],
      \"LoadId\": \"TEST\",
      \"Category\": \"call\",
      \"TPid\": \"TEST\",
      \"Tenant\": \"cgrates.org\",
      \"Subject\": \"*any\"
    }
  ]"
}

billing_engine_load_tariff_plan () {
  billing_engine_api "APIerSv1.LoadTariffPlanFromStorDb" "[
    {
      \"TPid\": \"TEST\",
      \"DryRun\": false,
      \"Validate\": true
    }
  ]"
}

billing_engine_api () {
  local method="$1"
  local params="$2"

  response=$(
    curl -s -X POST "http://billing-engine:$BILLING_ENGINE_HTTP_PORT/jsonrpc" \
      -H "Content-Type: application/json" \
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
}
