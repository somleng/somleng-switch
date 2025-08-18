#!/bin/sh
set -e

CONFIG_DIR="/etc/cgrates"
STORDB_SCRIPTS_DIR="/usr/share/cgrates/storage/postgres"
CONFIG_FILE="$CONFIG_DIR/cgrates.json"

# If command is NOT overridden, generate config
if [ "$#" -eq 0 ] || [ "$1" = "bootstrap" ]; then
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
  }
}
EOF
  fi
fi

# Bootstrap database if requested
if [ "$1" = "bootstrap" ]; then
  echo "🚀 Bootstrapping CGRateS database..."

  # Create user if it doesn't exist
  psql --host="$STORDB_HOST" --username=postgres --port="$STORDB_PORT" --dbname=postgres <<-SQL
    SELECT 'CREATE USER $STORDB_USER;'
    WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$STORDB_USER')\gexec
SQL

  # Create database if it doesn't exist
  psql --host="$STORDB_HOST" --username=postgres --port="$STORDB_PORT" --dbname=postgres <<-SQL
    SELECT 'CREATE DATABASE $STORDB_DBNAME OWNER $STORDB_USER;'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$STORDB_DBNAME')\gexec
SQL

  # Create necessary tables
  psql --host="$STORDB_HOST" --username=$STORDB_USER --port="$STORDB_PORT" --dbname=$STORDB_DBNAME -f $STORDB_SCRIPTS_DIR/create_cdrs_tables.sql
  psql --host="$STORDB_HOST" --username=$STORDB_USER --port="$STORDB_PORT" --dbname=$STORDB_DBNAME -f $STORDB_SCRIPTS_DIR/create_tariffplan_tables.sql

  # Run migrations
  cgr-migrator -config_path "$CONFIG_DIR" -exec=*stordb || true
  cgr-migrator -config_path "$CONFIG_DIR" -exec=*set_versions || true

  exit 0
fi

# If command is overridden, run it directly
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

echo "🚀 Starting CGRateS engine..."

# Run migrations (safe to re-run)
cgr-migrator -config_path "$CONFIG_DIR" -exec=*stordb || true

# Start CGRateS engine with generated configs
exec cgr-engine -config_path "$CONFIG_DIR" -logger=*stdout
