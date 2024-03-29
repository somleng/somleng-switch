#!/bin/sh

if [ -n "${UAS}" ]; then
  sipp -sf ./scenarios/uas.xml -bg -trace_msg
fi

if [ "$1" = "services" ]; then
  WS_SERVER_PORT="${WS_SERVER_PORT:="3001"}"
  FILE_SERVER_PORT="${FILE_SERVER_PORT:="8000"}"

  nohup node ./support/ws_server/test_server.js --port "$WS_SERVER_PORT" > test-server.log &
  nohup python3 -m http.server $FILE_SERVER_PORT > http-server.log &
  tail -f /dev/null
fi

exec "$@"
