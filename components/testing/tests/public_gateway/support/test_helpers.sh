#!/bin/sh

set -e

export CONTEXT="${CONTEXT:="public_gateway"}"
export DATABASE_URL="${DATABASE_URL:="postgres://$DATABASE_USERNAME:@$DATABASE_HOST:$DATABASE_PORT/opensips_${CONTEXT}_test"}"
export FIFO_NAME="${FIFO_NAME:="$FIFO_DIR/$CONTEXT"}"

reset_db () {
  psql -q $DATABASE_URL \
    -c "DELETE FROM load_balancer;" \
    -c "DELETE FROM address;"

  reload_opensips_tables
}

reload_opensips_tables () {
  echo "::{\"jsonrpc\":\"2.0\",\"method\":\"lb_reload\"}" | tee $FIFO_NAME > /dev/null
  echo "::{\"jsonrpc\":\"2.0\",\"method\":\"address_reload\"}" | tee $FIFO_NAME > /dev/null
}

create_address_entry () {
  ip="$1"

  psql -q $DATABASE_URL -c "INSERT INTO address (ip) VALUES('$ip');"
}
