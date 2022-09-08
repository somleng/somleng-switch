#!/bin/sh

set -e

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

create_load_balancer_entry () {
  gateway_identifier="$1"
  port="$2"
  psql -q $DATABASE_URL \
  -c "INSERT INTO load_balancer (group_id, dst_uri, resources, probe_mode) VALUES('1', 'sip:freeswitch:$port', '$gateway_identifier=fs://:secret@freeswitch:8021', 2);"
}

create_address_entry () {
  ip="$1"

  psql -q $DATABASE_URL -c "INSERT INTO address (ip) VALUES('$ip');"
}
