#!/bin/bash

# Local constants
FREESWITCH_CONTAINER_CONFIG_DIRECTORY="/etc/freeswitch/"
FREESWITCH_CONTAINER_STORAGE_DIRECTORY="/var/lib/freeswitch/storage"
FREESWITCH_CONTAINER_BINARY="/usr/bin/freeswitch"
FREESWITCH_USER="freeswitch"
FREESWITCH_GROUP="daemon"

set -e

if [ "$1" = 'freeswitch' ]; then
  export_fs_env_vars "$FREESWITCH_CONTAINER_CONFIG_DIRECTORY/env.xml"

  # Setup config directory
  chown -R "${FREESWITCH_USER}:${FREESWITCH_GROUP}" ${FREESWITCH_CONTAINER_CONFIG_DIRECTORY}

  # Setup storage directory
  chown -R "${FREESWITCH_USER}:${FREESWITCH_USER}" ${FREESWITCH_CONTAINER_STORAGE_DIRECTORY}

  # execute FreeSWITCH
  exec ${FREESWITCH_CONTAINER_BINARY} -u ${FREESWITCH_USER} -g ${FREESWITCH_GROUP} -nonat
fi

exec "$@"
