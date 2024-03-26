#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/uac_twilio.xml

log_file="uac_pcap_*_messages.log"
rm -f $log_file

media_server="$(dig +short freeswitch)"

reset_db
create_load_balancer_entry "gw" "5060"
create_address_entry $(hostname -i)
reload_opensips_tables

# start tcpdump here in background
( tcpdump -Xvv -i eth0 -s0 -w capture.pcap ) &
TCPDUMP_PID=$!

sipp -sf $scenario public_gateway:5060 -key username "+855715100850" -s 2222 -m 1 -trace_msg > /dev/null

echo "Killing TCPDUMP after sipp"

#kill tcpdump
kill $TCPDUMP_PID 

#extact audio
tshark -n -r capture.pcap -2 -R rtp -T fields -e rtp.payload | tr -d '\n',':' | xxd -r -p >call.rtp
sox -t al -r 8000 -c 1 call.rtp call.wav

#asset md5hash of wav == expected wav file
expectedFile=$current_dir/../../scenarios/files/expected.wav

reset_db

if [[ "$(md5sum call.wav)" != "$(md5sum $expectedFile)" ]]; then
	exit 1
fi
# Assert correct IP in SDP
if ! assert_in_file $log_file "c=IN IP4 $media_server"; then
	exit 1
fi
