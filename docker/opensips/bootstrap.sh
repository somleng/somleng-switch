#!/bin/sh

# See:
# https://github.com/OpenSIPS/opensips-cli
# https://github.com/OpenSIPS/opensips-cli/blob/master/docs/modules/database.md

set -e

if [ "$1" = 'create_db' ]; then
  DATABASE_MODULES="${DATABASE_MODULES:="dialog load_balancer"}"

  cat <<-EOT > /etc/opensips-cli.cfg
	[default]
	database_modules: $DATABASE_MODULES
	database_admin_url: $DATABASE_URL
	EOT

  opensips-cli -x database create

elif [ "$1" = 'add_module' ]; then
  cat <<-EOT > /etc/opensips-cli.cfg
	[default]
	database_admin_url: $DATABASE_URL
	EOT

  for module in $DATABASE_MODULES
  do
    echo $module
    opensips-cli -x database add "$module"
  done
else
  exec "$@"
fi
