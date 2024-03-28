#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/uac_connect.xml

log_file="uac_connect_*_messages.log"
rm -f $log_file

media_server="$(dig +short freeswitch)"
uac_server="$(dig +short testing)"

reset_db
create_load_balancer_entry "gw" "5060"
create_address_entry $(hostname -i)
reload_opensips_tables

# start tcpdump in background
nohup tcpdump -Xvv -i eth0 -s0 -w uac_connect.pcap &
tcpdump_pid=$!

sipp -sf $scenario public_gateway:5060 -key username "+855715100850" -s 2222 -m 1 -trace_msg > /dev/null

reset_db

# kill tcpdump
kill $tcpdump_pid

# extract audio
mkdir tmp

tshark -n -r uac_connect.pcap -2 -R rtp -T fields -e rtp.payload | tr -d '\n',':' | xxd -r -p > uac_connect.rtp
sox -t al -r 8000 -c 1 uac_connect.rtp tmp/temp1.wav
ffmpeg -y -i tmp/temp1.wav -ss 6.3 tmp/temp2.wav 2> /dev/null
ffmpeg -y -i tmp/temp2.wav -af silenceremove=1:0:-40dB,areverse,silenceremove=1:0:-50dB,areverse uac_connect.wav 2> /dev/null

rm -r tmp

actual_md5=$(md5sum uac_connect.wav | head -c 32)
expected_md5="328489d203813f6e216a1d77c41b3ad9"

echo "Act MD5: $actual_md5"
echo "Exp MD5: $expected_md5"

if [[ "$actual_md5" != "$expected_md5" ]]; then
	exit 1
fi
# Assert correct IP in SDP
if ! assert_in_file $log_file "c=IN IP4 $media_server"; then
	exit 1
fi
