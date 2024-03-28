#!/bin/sh

if [ "$1" = 'start' ]; then
  WS_SERVER_PORT="${WS_SERVER_PORT:="3001"}"

  sipp -sf ./scenarios/uas.xml -bg -trace_msg
  nohup node ./support/ws_server/test_server.js --port "$WS_SERVER_PORT" > test-server.log &
  tail -f /dev/null
fi

exec "$@"
