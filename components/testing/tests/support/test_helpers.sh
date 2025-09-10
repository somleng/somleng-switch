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

billing_engine_set_charger_profile () {
  response=$(
    curl -s -X POST "http://billing-engine:$BILLING_ENGINE_HTTP_PORT/jsonrpc" \
      -H "Content-Type: application/json" \
      -d '{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "APIerSv1.SetChargerProfile",
        "params": [
          {
            "ID": "CHARGER_Default",
            "FilterIDs": [],
            "AttributeIDs": ["*none"],
            "RunID": "default",
            "Weight": 0
          }
        ]
      }'
  )

  error=$(echo "$response" | jq -r '.error')

  if [ "$error" != "null" ]; then
    echo "Error in response: $error"
    return 1
  fi
}
