#!/bin/sh

if [ -n "${UAS}" ]; then
  sipp -sf ./scenarios/uas.xml -bg -trace_msg
fi

if [ "$1" = "services" ]; then
  WS_SERVER_PORT="${WS_SERVER_PORT:="3001"}"
  FILE_SERVER_PORT="${FILE_SERVER_PORT:="8000"}"
  FILE_SERVER_LOG_FILE="${FILE_SERVER_LOG_FILE:="http-server.log"}"

  nohup node ./support/ws_server/test_server.js --port "$WS_SERVER_PORT" > test-server.log &
  nohup python3 -u -m http.server $FILE_SERVER_PORT 2> $FILE_SERVER_LOG_FILE &
  tail -f /dev/null
fi

exec "$@"
