#!/bin/sh

set -e

reset_db () {
  psql -q $DATABASE_URL \
    -c "DELETE FROM load_balancer;" \
    -c "DELETE FROM address;" \
    -c "DELETE FROM subscriber;" \
    -c "DELETE FROM location;" \
    -c "DELETE FROM domain;" \
    -c "DELETE FROM rtpengine;"

  reload_opensips_tables
}

reload_opensips_tables () {
  echo "::{\"jsonrpc\":\"2.0\",\"method\":\"lb_reload\"}" | tee $PUBLIC_GATEWAY_FIFO_NAME > /dev/null
  echo "::{\"jsonrpc\":\"2.0\",\"method\":\"address_reload\"}" | tee $PUBLIC_GATEWAY_FIFO_NAME > /dev/null
  echo "::{\"jsonrpc\":\"2.0\",\"method\":\"domain_reload\"}" | tee $PUBLIC_GATEWAY_FIFO_NAME $CLIENT_GATEWAY_FIFO_NAME > /dev/null
  echo "::{\"jsonrpc\":\"2.0\",\"method\":\"rtpengine_reload\"}" | tee $PUBLIC_GATEWAY_FIFO_NAME $CLIENT_GATEWAY_FIFO_NAME > /dev/null
}

create_load_balancer_entry () {
  gateway_identifier="$1"
  port="$2"
  psql -q $DATABASE_URL \
  -c "INSERT INTO load_balancer (group_id, dst_uri, resources, probe_mode) VALUES('1', 'sip:freeswitch:$port', '$gateway_identifier=fs://:secret@freeswitch:8021', 2);"
}

create_subscriber_entry () {
  username="$1"
  password="$2"
  realm=$3
  input="$username:$realm:$password"

  md5_hash=$(echo -n "$input" | md5sum | head -c 32)
  sha256_hash=$(echo -n "$input" | sha256sum | head -c 64)
  sha512_hash=$(echo -n "$input" | sha512sum | head -c 64)

  psql -q $DATABASE_URL -c "INSERT INTO subscriber (username,ha1,ha1_sha256,ha1_sha512t256) VALUES('$username', '$md5_hash', '$sha256_hash', '$sha512_hash');"
}

create_address_entry () {
  ip="$1"

  psql -q $DATABASE_URL -c "INSERT INTO address (ip) VALUES('$ip');"
}

create_domain_entry () {
  domain="$1"
  timestamp="$(date +'%F %T')"

  psql -q $DATABASE_URL -c "INSERT INTO domains (domain,last_modified) VALUES('$domain', '$timestamp');"
}

create_rtpengine_entry () {
  socket="$1"

  psql -q $DATABASE_URL -c "INSERT INTO rtpengine (socket,set_id) VALUES('$socket', '0');"
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
