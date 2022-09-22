#!/bin/sh

set -e

export CONTEXT="${CONTEXT:="client_gateway"}"
export DATABASE_URL="${DATABASE_URL:="postgres://$DATABASE_USERNAME:@$DATABASE_HOST:$DATABASE_PORT/opensips_${CONTEXT}_test"}"
export FIFO_NAME="${FIFO_NAME:="$FIFO_DIR/$CONTEXT"}"

reset_db () {
  psql -q $DATABASE_URL \
    -c "DELETE FROM load_balancer;" \
    -c "DELETE FROM subscriber;" \
    -c "DELETE FROM location;" \
    -c "DELETE FROM domain;" \
    -c "DELETE FROM rtpengine;"

  reload_opensips_tables
}

reload_opensips_tables () {
  echo "::{\"jsonrpc\":\"2.0\",\"method\":\"lb_reload\"}" | tee $FIFO_NAME > /dev/null
  echo "::{\"jsonrpc\":\"2.0\",\"method\":\"domain_reload\"}" | tee $FIFO_NAME > /dev/null
  echo "::{\"jsonrpc\":\"2.0\",\"method\":\"rtpengine_reload\"}" | tee $FIFO_NAME > /dev/null
}

create_domain_entry () {
  domain="$1"
  timestamp="$(date +'%F %T')"

  psql -q $DATABASE_URL -c "INSERT INTO domain (domain,last_modified) VALUES('$domain', '$timestamp');"
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

create_rtpengine_entry () {
  socket="$1"

  psql -q $DATABASE_URL -c "INSERT INTO rtpengine (socket,set_id) VALUES('$socket', '0');"
}
