#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/smart_inbound.xml

curl -X POST -d @$scenario http://switch:8080/calls -H "Content-Type: application/json" -H "Accept: application/json"
