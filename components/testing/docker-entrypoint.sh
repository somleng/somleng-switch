#!/bin/sh

if [ "$1" = 'start' ]; then
  WS_SERVER_PORT="${WS_SERVER_PORT:="3001"}"
  HTTP_SERVER_PORT="${HTTP_SERVER_PORT:="8000"}"

  sipp -sf ./scenarios/uas.xml -bg -trace_msg
  nohup node ./support/ws_server/test_server.js --port "$WS_SERVER_PORT" > test-server.log &
  nohup python3 -m http.server $HTTP_SERVER_PORT > http-server.log &
  tail -f /dev/null
fi

exec "$@"
