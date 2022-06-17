#!/bin/bash

set -e

if [ "$1" = 'freeswitch' ]; then
  # Local constants
  FS_CACHE_DIRECTORY="${FS_CACHE_DIRECTORY:-"/var/lib"}"
  FREESWITCH_CONTAINER_CONFIG_DIRECTORY="/etc/freeswitch/"
  FREESWITCH_STORAGE_DIRECTORY="${FS_CACHE_DIRECTORY}/freeswitch/storage"
  FREESWITCH_TTS_CACHE_DIRECTORY="${FS_CACHE_DIRECTORY}/freeswitch/tts_cache"

  FREESWITCH_CONTAINER_BINARY="/usr/bin/freeswitch"
  FREESWITCH_USER="freeswitch"
  FREESWITCH_GROUP="daemon"

  # Setup directories

  for directory in "$FREESWITCH_CONTAINER_CONFIG_DIRECTORY" "$FREESWITCH_STORAGE_DIRECTORY" "$FREESWITCH_TTS_CACHE_DIRECTORY"
  do
    mkdir -p "$directory"
    chown -R "$FREESWITCH_USER:$FREESWITCH_GROUP" "$directory"
  done

  export_fs_env_vars "$FREESWITCH_CONTAINER_CONFIG_DIRECTORY/env.xml"

  # execute FreeSWITCH
  exec "$FREESWITCH_CONTAINER_BINARY" -u "$FREESWITCH_USER" -g "$FREESWITCH_GROUP" -nonat -storage "$FREESWITCH_STORAGE_DIRECTORY"
fi

exec "$@"
