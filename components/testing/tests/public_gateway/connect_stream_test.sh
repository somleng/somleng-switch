#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/uac_connect.xml

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

# kill tcpdump
kill $TCPDUMP_PID

# extract audio
tshark -n -r capture.pcap -2 -R rtp -T fields -e rtp.payload | tr -d '\n',':' | xxd -r -p >call.rtp
sox -t al -r 8000 -c 1 call.rtp call.wav
#trim silence
#ffmpeg -y -i call.wav -af silenceremove=1:0:-40dB,areverse,silenceremove=1:0:-50dB,areverse trim.wav
sox call.wav trim.wav silence 1 0.1 0.1% 1 0.5 0.1% 

#asset md5hash of wav == expected wav file
expectedFile=$current_dir/../../scenarios/files/expected.wav

reset_db

actual_md5=$(md5sum trim.wav | head -c 32)
expected_md5=$(md5sum $expectedFile | head -c 32)

echo "Act MD5: $actual_md5"
echo "Exp MD5: $expected_md5"

if [[ "$actual_md5" != "$expected_md5" ]]; then
	exit 1
fi
# Assert correct IP in SDP
if ! assert_in_file $log_file "c=IN IP4 $media_server"; then
	exit 1
fi
