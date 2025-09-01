#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

response=$(curl -s -X POST http://billing-engine:$BILLING_ENGINE_HTTP_PORT/jsonrpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"ApierV2.Ping","params":[]}')

# Extract the result field
result=$(echo "$response" | jq -r '.result')

# Check if result is "Pong"
if [ "$result" = "Pong" ]; then
  echo "Test passed: received Pong"
else
  echo "Test failed: expected Pong, got '$result'"
  echo "Full response:"
  echo "$response"
  exit 1
fi
