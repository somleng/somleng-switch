#!/bin/sh

set -e

reset_db () {
  psql -q $DATABASE_URL \
    -c "DELETE FROM load_balancer;" \
    -c "DELETE FROM address;"

  reload_opensips_tables
}

reload_opensips_tables () {
  echo "::{\"jsonrpc\":\"2.0\",\"method\":\"lb_reload\"}" > $OPENSIPS_FIFO_NAME
  echo "::{\"jsonrpc\":\"2.0\",\"method\":\"address_reload\"}" > $OPENSIPS_FIFO_NAME
}

create_load_balancer_entry () {
  gateway_identifier="$1"
  port="$2"
  psql -q $DATABASE_URL \
  -c "INSERT INTO load_balancer (group_id, dst_uri, resources, probe_mode) VALUES('1', 'sip:freeswitch:$port', '$gateway_identifier=fs://:secret@freeswitch:8021', 2);"
}

create_address_entry () {
  ip="$1"
  psql -q $DATABASE_URL -c "INSERT INTO address (ip, mask) VALUES('$ip', 32);"
}

assert_in_file () {
  filename="$1"
  test_string="$2"

  file=$(find . -type f -iname $(basename "$filename"))

  if ! grep -q "$test_string" $file; then
    cat <<-EOT
		Error:
		Expected $test_string to be found in $file but was not:
		`cat $file`
		EOT

    return 1
  fi
}

assert_not_in_file () {
  filename="$1"
  test_string="$2"

  file=$(find . -type f -iname $(basename "$filename"))

  if grep -q "$test_string" $file; then
    cat <<-EOT
		Error:
		Expected $test_string not to be found in $file but was found:
		`cat $file`
		EOT

    return 1
  fi
}
