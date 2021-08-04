#!/bin/bash

# Local constants
DEFAULT_CONTAINER_RECORDINGS_DIRECTORY="/freeswitch-recordings"
FREESWITCH_CONTAINER_CONFIG_DIRECTORY="/etc/freeswitch/"
FREESWITCH_CONTAINER_STORAGE_DIRECTORY="/var/lib/freeswitch/storage"
FREESWITCH_CONTAINER_BINARY="/usr/bin/freeswitch"
FREESWITCH_USER="freeswitch"
FREESWITCH_GROUP="daemon"

export FS_MOD_RAYO_RECORD_FILE_PREFIX="${FS_MOD_RAYO_RECORD_FILE_PREFIX:-$DEFAULT_CONTAINER_RECORDINGS_DIRECTORY}"

set -e

if [ "$1" = 'freeswitch' ]; then
  export_fs_env_vars "$FREESWITCH_CONTAINER_CONFIG_DIRECTORY/env.xml"
  export_aws_polly_voices "$FREESWITCH_CONTAINER_CONFIG_DIRECTORY/autoload_configs/polly_voices.xml"

  # Setup recordings directory
  mkdir -p ${FS_MOD_RAYO_RECORD_FILE_PREFIX}
  chown -R "${FREESWITCH_USER}:${FREESWITCH_GROUP}" ${FS_MOD_RAYO_RECORD_FILE_PREFIX}

  # Setup config directory
  chown -R "${FREESWITCH_USER}:${FREESWITCH_GROUP}" ${FREESWITCH_CONTAINER_CONFIG_DIRECTORY}

  # Setup storage directory
  chown -R "${FREESWITCH_USER}:${FREESWITCH_USER}" ${FREESWITCH_CONTAINER_STORAGE_DIRECTORY}

  # execute FreeSWITCH
  exec ${FREESWITCH_CONTAINER_BINARY} -u ${FREESWITCH_USER} -g ${FREESWITCH_GROUP}
fi

exec "$@"
