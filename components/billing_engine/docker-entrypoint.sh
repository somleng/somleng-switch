#!/bin/sh
set -e

CONFIG_DIR="/etc/cgrates"
STORDB_SCRIPTS_DIR="/usr/share/cgrates/storage/postgres"
CONFIG_FILE="$CONFIG_DIR/cgrates.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "📝 Generating CGRateS config..."
  mkdir -p "$CONFIG_DIR"

  cat > "$CONFIG_FILE" <<EOF
{
  "general": {
    "log_level": ${LOG_LEVEL:-3}
  },
  "stor_db": {
    "db_type": "*postgres",
    "db_name": "${STORDB_DBNAME}",
    "db_user": "${STORDB_USER}",
    "db_password": "${STORDB_PASSWORD}",
    "db_host": "${STORDB_HOST}",
    "db_port": ${STORDB_PORT:-5432},
    "opts": {
      "sqlLogLevel": 4
    }
  },
  "data_db": {
    "db_type": "*redis",
    "db_user": "${DATADB_USER}",
    "db_host": "${DATADB_HOST}",
    "db_port": ${DATADB_PORT:-6379},
    "db_name": "${DATADB_DBNAME:-1}"
  },
  "sessions": {
    "enabled": true
  },
  "freeswitch_agent": {
    "enabled": true,
    "sessions_conns": ["*birpc_internal"],
    "create_cdr": true,
    "event_socket_conns": [
      {
        "address": "${EVENT_SOCKET_HOST}",
        "password": "${EVENT_SOCKET_PASSWORD}",
        "reconnects": -1,
        "alias": ""
      }
    ]
  },
  "http": {
    "json_rpc_url": "",
    "ws_url": ""
  }
}
EOF
fi

if [ "$#" -eq 0 ]; then
  cgr-migrator -config_path "$CONFIG_DIR" -exec=*stordb || true
  exec cgr-engine -config_path "$CONFIG_DIR" -logger=*stdout
else
  exec "$@"
fi
