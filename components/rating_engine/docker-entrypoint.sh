#!/bin/sh
set -e

CONFIG_DIR="/etc/cgrates"
STORDB_SCRIPTS_DIR="/usr/share/cgrates/storage/postgres"
CONFIG_FILE="$CONFIG_DIR/cgrates.json"
CONNECTION_MODE="${CONNECTION_MODE:-"*internal"}"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "📝 Generating CGRateS config..."
  mkdir -p "$CONFIG_DIR"

  if [ "${SERVER_MODE}" = "engine" ]; then
    cat > "$CONFIG_FILE" <<EOF
    {
      "general": {
        "log_level": ${LOG_LEVEL:-3},
        "logger": "*stdout",
        "default_request_type": "*postpaid"
      },
      "stor_db": {
        "db_type": "*postgres",
        "db_name": "${STORDB_DBNAME}",
        "db_user": "${STORDB_USER}",
        "db_password": "${STORDB_PASSWORD}",
        "db_host": "${STORDB_HOST}",
        "db_port": ${STORDB_PORT:-5432},
        "opts": {
          "sqlLogLevel": 4,
          "pgSSLMode": "${STORDB_SSL_MODE:-"disable"}"
        }
      },
      "data_db": {
        "db_type": "*redis",
        "db_user": "${DATADB_USER}",
        "db_password": "${DATADB_PASSWORD}",
        "db_host": "${DATADB_HOST}",
        "db_port": ${DATADB_PORT:-6379},
        "db_name": "${DATADB_DBNAME:-0}",
        "opts": {
          "redisTLS": ${DATADB_TLS:-false},
        }
      },
      "sessions": {
        "enabled": true,
        "attributes_conns": ["${CONNECTION_MODE}"],
        "chargers_conns": ["${CONNECTION_MODE}"],
        "rals_conns": ["${CONNECTION_MODE}"],
        "cdrs_conns": ["${CONNECTION_MODE}"],
        "debit_interval": "2s"
      },
      "attributes": {
        "enabled": true
      },
      "chargers": {
        "enabled": true,
        "attributes_conns": ["${CONNECTION_MODE}"],
      },
      "cdrs": {
        "enabled": true,
        "store_cdrs": true,
        "thresholds_conns": ["${CONNECTION_MODE}"],
        "rals_conns": ["${CONNECTION_MODE}"],
        "chargers_conns": ["${CONNECTION_MODE}"]
      },
      "freeswitch_agent": {
        "enabled": true,
        "sessions_conns": ["*bijson_localhost"],
        "create_cdr": true,
        "extra_fields": [
          "~*req.variable_sip_h_X-Somleng-CallSid",
          "~*req.variable_sip_rh_X-Somleng-CallSid",
          "~*req.variable_somleng_call_sid"
        ],
        "event_socket_conns": [
          {
            "address": "${EVENT_SOCKET_HOST}",
            "password": "${EVENT_SOCKET_PASSWORD}",
            "reconnects": -1,
            "alias": ""
          }
        ]
      },
      "rals": {
        "enabled": true,
        "thresholds_conns": ["${CONNECTION_MODE}"],
        "apiers_conns": ["${CONNECTION_MODE}"]
      },
      "thresholds": {
        "enabled": true,
        "string_indexed_fields": ["*req.Account"],
      },
      "listen": {
        "http": "${HTTP_LISTEN_ADDRESS:-"127.0.0.1:2080"}"
      },
      "apiers": {
        "enabled": true
      },
      "http": {
        "json_rpc_url": "${JSON_RPC_URL:-/jsonrpc}",
        "use_basic_auth": true,
        "auth_users": {
          "${JSON_RPC_USERNAME}": "$(echo -n "${JSON_RPC_PASSWORD}" | base64)"
        }
      },
      "schedulers": {
        "enabled": true,
        "cdrs_conns": ["${CONNECTION_MODE}"]
      },
      "caches": {
        "partitions": {
          "*destinations": {
            "ttl": "${CACHE_TTL:-"60s"}",
          },
          "*reverse_destinations": {
            "ttl": "${CACHE_TTL:-"60s"}",
          },
          "*rating_plans": {
            "ttl": "${CACHE_TTL:-"60s"}",
          },
          "*rating_profiles": {
            "ttl": "${CACHE_TTL:-"60s"}",
          },
          "*charger_profiles": {
            "ttl": "${CACHE_TTL:-"60s"}",
          },
          "*load_ids": {
            "ttl": "${CACHE_TTL:-"60s"}",
          }
        }
      }
    }
EOF
  elif [ "${SERVER_MODE}" = "api" ]; then
    cat > "$CONFIG_FILE" <<EOF
    {
      "general": {
        "log_level": ${LOG_LEVEL:-3},
        "logger": "*stdout",
        "default_request_type": "*postpaid"
      },
      "stor_db": {
        "db_type": "*postgres",
        "db_name": "${STORDB_DBNAME}",
        "db_user": "${STORDB_USER}",
        "db_password": "${STORDB_PASSWORD}",
        "db_host": "${STORDB_HOST}",
        "db_port": ${STORDB_PORT:-5432},
        "opts": {
          "sqlLogLevel": 4,
          "pgSSLMode": "${STORDB_SSL_MODE:-"disable"}"
        }
      },
      "data_db": {
        "db_type": "*redis",
        "db_user": "${DATADB_USER}",
        "db_password": "${DATADB_PASSWORD}",
        "db_host": "${DATADB_HOST}",
        "db_port": ${DATADB_PORT:-6379},
        "db_name": "${DATADB_DBNAME:-0}",
        "opts": {
          "redisTLS": ${DATADB_TLS:-false},
        }
      },
      "sessions": {
        "enabled": true,
        "attributes_conns": ["${CONNECTION_MODE}"],
        "chargers_conns": ["${CONNECTION_MODE}"],
        "rals_conns": ["${CONNECTION_MODE}"],
        "cdrs_conns": ["${CONNECTION_MODE}"],
      },
      "attributes": {
        "enabled": true
      },
      "chargers": {
        "enabled": true,
        "attributes_conns": ["${CONNECTION_MODE}"],
      },
      "cdrs": {
        "enabled": true,
        "store_cdrs": true,
        "thresholds_conns": ["${CONNECTION_MODE}"],
        "rals_conns": ["${CONNECTION_MODE}"],
        "chargers_conns": ["${CONNECTION_MODE}"]
      },
      "rals": {
        "enabled": true,
        "thresholds_conns": ["${CONNECTION_MODE}"],
        "apiers_conns": ["${CONNECTION_MODE}"]
      },
      "thresholds": {
        "enabled": true,
        "string_indexed_fields": ["*req.Account"],
      },
      "listen": {
        "http": "${HTTP_LISTEN_ADDRESS:-"127.0.0.1:2080"}"
      },
      "apiers": {
        "enabled": true
      },
      "http": {
        "json_rpc_url": "${JSON_RPC_URL:-/jsonrpc}",
        "use_basic_auth": true,
        "auth_users": {
          "${JSON_RPC_USERNAME}": "$(echo -n "${JSON_RPC_PASSWORD}" | base64)"
        }
      },
      "schedulers": {
        "enabled": true,
        "cdrs_conns": ["${CONNECTION_MODE}"]
      }
    }
EOF
  else
    echo "Invalid SERVER_MODE: ${SERVER_MODE}"
    exit 1
  fi
fi

if [ "$#" -eq 0 ]; then
  if [ -n "${BOOTSTRAP_DB}" ]; then
    echo "🚀 Bootstrapping CGRateS database..."

    DB_EXISTS=$(PGPASSWORD="$STORDB_PASSWORD" psql --host="$STORDB_HOST" --username="$STORDB_USER" --port="$STORDB_PORT" --dbname=postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$STORDB_DBNAME';")
    if [ "$DB_EXISTS" = "1" ]; then
      echo "Database $STORDB_DBNAME already exists."
    else
      PGPASSWORD="$STORDB_PASSWORD" psql --host="$STORDB_HOST" --username="$STORDB_USER" --port="$STORDB_PORT" --dbname=postgres -c "CREATE DATABASE \"$STORDB_DBNAME\" OWNER \"$STORDB_USER\";"

      # Create necessary tables
      PGPASSWORD="$STORDB_PASSWORD" psql --host="$STORDB_HOST" --username="$STORDB_USER" --port="$STORDB_PORT" --dbname="$STORDB_DBNAME" -f "$STORDB_SCRIPTS_DIR/create_cdrs_tables.sql"
      PGPASSWORD="$STORDB_PASSWORD" psql --host="$STORDB_HOST" --username="$STORDB_USER" --port="$STORDB_PORT" --dbname="$STORDB_DBNAME" -f "$STORDB_SCRIPTS_DIR/create_tariffplan_tables.sql"
      PGPASSWORD="$STORDB_PASSWORD" psql --host="$STORDB_HOST" --username="$STORDB_USER" --port="$STORDB_PORT" --dbname="$STORDB_DBNAME" -v ON_ERROR_STOP=1 -c "CREATE INDEX IF NOT EXISTS idx_cdrs_origin_id ON cdrs (origin_id); CREATE INDEX IF NOT EXISTS idx_cdrs_cost ON cdrs (cost);"

      cgr-migrator -config_path "$CONFIG_DIR" -exec=*set_versions || true

      echo "✅ Bootstrap completed."
    fi
  fi

  cgr-migrator -config_path "$CONFIG_DIR" -exec=*stordb || true
  exec cgr-engine -config_path "$CONFIG_DIR" -logger=*stdout
else
  exec "$@"
fi
