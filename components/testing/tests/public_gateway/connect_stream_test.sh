#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/uac_connect.xml
artifacts_dir=connect_stream_test_files

log_file="uac_connect_*_messages.log"
rm -f $log_file

media_server="$(dig +short freeswitch)"
uac_server="$(dig +short testing)"

reset_db
create_load_balancer_entry "gw" "5060"
create_address_entry $(hostname -i)
reload_opensips_tables

rm -rf $artifacts_dir
mkdir -p $artifacts_dir

# start tcpdump in background
nohup tcpdump -Xvv -i eth0 -s0 -w $artifacts_dir/uac_connect.pcap &
tcpdump_pid=$!

sipp -sf $scenario public_gateway:5060 -key username "+855715100850" -s 2222 -m 1 -trace_msg > /dev/null

reset_db

# kill tcpdump
kill $tcpdump_pid

# extract audio
tshark -n -r $artifacts_dir/uac_connect.pcap -2 -R rtp -T fields -e rtp.payload | tr -d '\n',':' | xxd -r -p > $artifacts_dir/uac_connect.rtp
sox -t al -r 8000 -c 1 $artifacts_dir/uac_connect.rtp $artifacts_dir/uac_connect_full_audio.wav
ffmpeg -y -i $artifacts_dir/uac_connect_full_audio.wav -ss 6.3 $artifacts_dir/uac_connect_callee_audio.wav 2> /dev/null
ffmpeg -y -i $artifacts_dir/uac_connect_callee_audio.wav -af silenceremove=1:0:-40dB,areverse,silenceremove=1:0:-50dB,areverse $artifacts_dir/uac_connect_trimmed_callee_audio.wav 2> /dev/null

actual_md5=$(md5sum $artifacts_dir/uac_connect_trimmed_callee_audio.wav | head -c 32)
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
