#!/bin/bash

set -e

if [ "$1" = 'freeswitch' ]; then
  # Local constants
  FS_CONTAINER_CONFIG_DIRECTORY="/etc/freeswitch/"

  FS_CONTAINER_BINARY="/usr/bin/freeswitch"
  FS_USER="freeswitch"
  FS_GROUP="daemon"

  export_fs_env_vars "$FS_CONTAINER_CONFIG_DIRECTORY/env.xml"

  # Setup directories

  for directory in "$FS_LOG_DIRECTORY" "$FS_CONTAINER_CONFIG_DIRECTORY" "$FS_STORAGE_DIRECTORY" "$FS_TTS_CACHE_DIRECTORY"
  do
    mkdir -p "$directory"
    chown "$FS_USER:$FS_GROUP" "$directory"
  done

  # execute FreeSWITCH
  exec "$FS_CONTAINER_BINARY" -u "$FS_USER" -g "$FS_GROUP" -nonat -storage "$FS_STORAGE_DIRECTORY"
fi

exec "$@"
