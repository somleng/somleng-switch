#!/bin/sh

if [ "$1" = 'start' ]; then
  WS_SERVER_AUDIO_OUTPUT="${WS_SERVER_AUDIO_OUTPUT:="audio.raw"}"
  WS_SERVER_PORT="${WS_SERVER_PORT:="3001"}"

  sipp -sf ./scenarios/uas.xml -bg -trace_msg
  nohup node ./support/ws_server/server_twilio.js "$WS_SERVER_AUDIO_OUTPUT" --port "$WS_SERVER_PORT" > ws-server.log &
  tail -f /dev/null
fi

exec "$@"
