#!/bin/sh

response=$(wget --quiet \
  --header="Content-Type: application/json" \
  --post-data='{"jsonrpc":"2.0","id":1,"method":"ApierV2.Ping","params":[]}' \
  -O - "http://${HTTP_LISTEN_ADDRESS:-127.0.0.1:2080}${JSON_RPC_URL:-/jsonrpc}")

# Extract the "result" value from JSON using grep/sed
result=$(echo "$response" | grep -o '"result"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"\(.*\)"/\1/')

if [ "$result" = "Pong" ]; then
  exit 0  # healthy
else
  exit 1  # unhealthy
fi
