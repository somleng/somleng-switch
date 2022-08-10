#!/bin/sh

set -e

echo "Running: `basename $0`"

current_dir=$(dirname "$(readlink -f "$0")")
scenario=$current_dir/../scenarios/zamtel_sip_options.xml

sipp -sf $scenario opensips:5080 -s 1234 -m 1 > /dev/null
