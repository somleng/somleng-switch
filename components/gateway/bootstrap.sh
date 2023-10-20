#!/bin/sh

# See:
# https://github.com/OpenSIPS/opensips-cli
# https://github.com/OpenSIPS/opensips-cli/blob/master/docs/modules/database.md

set -e

ADMIN_DATABASE_URL="postgresql://$DATABASE_USERNAME:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT/postgres"
DATABASE_URL="postgresql://$DATABASE_USERNAME:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT"

if [ "$1" = 'create_db' ]; then
  if [ "$2" = 'public_gateway' ]; then
    DATABASE_MODULES="${DATABASE_MODULES:="dialog load_balancer permissions"}"
  fi

  if [ "$2" = 'client_gateway' ]; then
    DATABASE_MODULES="${DATABASE_MODULES:="dialog load_balancer auth_db usrloc domain rtpengine"}"
  fi

  PGPASSWORD=$DATABASE_PASSWORD

  cat <<-EOT > /etc/opensips-cli.cfg
	[default]
	database_modules: $DATABASE_MODULES
	database_admin_url: $ADMIN_DATABASE_URL
	database_url: $DATABASE_URL
	database_name: $DATABASE_NAME
	EOT

  psql --host=$DATABASE_HOST --username=$DATABASE_USERNAME --port=$DATABASE_PORT --dbname postgres <<-SQL
    SELECT 'CREATE USER opensips;' WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'opensips')\gexec
	SQL

  opensips-cli -x database create
elif [ "$1" = 'add_module' ]; then
  cat <<-EOT > /etc/opensips-cli.cfg
	[default]
	database_admin_url: $ADMIN_DATABASE_URL
	database_url: $DATABASE_URL
	database_name: $DATABASE_NAME
	EOT

  for module in $DATABASE_MODULES
  do
    echo $module
    opensips-cli -x database add "$module"
  done
else
  exec "$@"
fi
