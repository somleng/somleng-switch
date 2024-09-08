#!/bin/sh

set -e

create_load_balancer_entry () {
  gateway_identifier="$1"
  port="$2"
  group_id="$3"
  group_id="${group_id:=1}"
  psql -q $DATABASE_URL \
  -c "INSERT INTO load_balancer (group_id, dst_uri, resources, probe_mode) VALUES('$group_id', 'sip:freeswitch:$port', '$gateway_identifier=fs://:secret@freeswitch:8021', 2);"
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
