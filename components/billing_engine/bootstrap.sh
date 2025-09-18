#!/bin/sh
set -e

CONFIG_DIR="/etc/cgrates"
STORDB_SCRIPTS_DIR="/usr/share/cgrates/storage/postgres"
CONFIG_FILE="$CONFIG_DIR/cgrates.json"

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
    },
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

if [ "$#" -eq 0 ]; then
  echo "🚀 Bootstrapping CGRateS database..."

  # Create user if not exists
  psql --host="$STORDB_HOST" --username=postgres --port="$STORDB_PORT" --dbname=postgres <<-SQL
SELECT 'CREATE USER $STORDB_USER;'
WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$STORDB_USER')\gexec
SQL

  # Create database if not exists
  psql --host="$STORDB_HOST" --username=postgres --port="$STORDB_PORT" --dbname=postgres <<-SQL
SELECT 'CREATE DATABASE $STORDB_DBNAME OWNER $STORDB_USER;'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$STORDB_DBNAME')\gexec
SQL

  # Create necessary tables
  psql --host="$STORDB_HOST" --username="$STORDB_USER" --port="$STORDB_PORT" --dbname="$STORDB_DBNAME" -f "$STORDB_SCRIPTS_DIR/create_cdrs_tables.sql"
  psql --host="$STORDB_HOST" --username="$STORDB_USER" --port="$STORDB_PORT" --dbname="$STORDB_DBNAME" -f "$STORDB_SCRIPTS_DIR/create_tariffplan_tables.sql"

  cgr-migrator -config_path "$CONFIG_DIR" -exec=*set_versions || true

  echo "✅ Bootstrap completed."
else
  exec "$@"
fi
