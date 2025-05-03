#!/bin/sh

set -e

current_dir=$(dirname "$(readlink -f "$0")")
source $current_dir/support/test_helpers.sh
source $current_dir/../support/test_helpers.sh

scenario=$current_dir/../../scenarios/uac_connect.xml
artifacts_dir=dial_test_files

log_file="uac_connect_*_messages.log"
rm -f $log_file

media_server="$(dig +short freeswitch)"

reset_db
create_load_balancer_entry "gw" "5060"
create_address_entry $(hostname -i)
reload_opensips_tables

rm -rf $artifacts_dir
mkdir -p $artifacts_dir

# start tcpdump in background
nohup tcpdump -Xvv -i eth0 -s0 -w $artifacts_dir/uac_connect.pcap &
tcpdump_pid=$!

sipp -sf $scenario public_gateway:5060 -key username "+855715100850" -s 3333 -m 1 -trace_msg > /dev/null

reset_db

# kill tcpdump
kill $tcpdump_pid

# extract RTP from PCAP
# tshark -n -r $artifacts_dir/uac_connect.pcap -2 -R rtp -T fields -e rtp.payload | tr -d '\n',':' | xxd -r -p > $artifacts_dir/uac_connect.rtp
# # Convert RTP to wav
# sox -t al -r 8000 -c 1 $artifacts_dir/uac_connect.rtp $artifacts_dir/uac_connect_full_audio.wav
# # Cut the audio from the ws server
# ffmpeg -y -i $artifacts_dir/uac_connect_full_audio.wav -ss 8.5 -to 12 $artifacts_dir/uac_connect_ws_server_audio.wav 2> /dev/null
# # Remove silence
# ffmpeg -y -i $artifacts_dir/uac_connect_ws_server_audio.wav -af silenceremove=1:0:-30dB,areverse,silenceremove=1:0:-30dB,areverse $artifacts_dir/uac_connect_trimmed_ws_server_audio.wav 2> /dev/null
# # Cut the play verb audio
# ffmpeg -y -i $artifacts_dir/uac_connect_full_audio.wav -ss 12.2 $artifacts_dir/uac_connect_play_verb_audio.wav 2> /dev/null
# # Remove silence
# ffmpeg -y -i $artifacts_dir/uac_connect_play_verb_audio.wav -af silenceremove=1:0:-30dB,areverse,silenceremove=1:0:-30dB,areverse $artifacts_dir/uac_connect_trimmed_play_verb_audio.wav 2> /dev/null

# ws_server_audio_md5=$(md5sum $artifacts_dir/uac_connect_trimmed_ws_server_audio.wav | head -c 32)
# play_verb_audio_md5=$(md5sum $artifacts_dir/uac_connect_trimmed_play_verb_audio.wav | head -c 32)
# expected_audio_md5="1c1542575c47ef620c8344438e75095f"

# echo "Actual ws_server_audio_md5: $ws_server_audio_md5"
# echo "Actual play_verb_audio_md5: $play_verb_audio_md5"
# echo "Expected audio_md5: $expected_audio_md5"

# if [[ "$ws_server_audio_md5" != "$expected_audio_md5" ]]; then
# 	exit 1
# fi

# if [[ "$play_verb_audio_md5" != "$expected_audio_md5" ]]; then
# 	exit 1
# fi

# # Assert correct IP in SDP
# if ! assert_in_file $log_file "c=IN IP4 $media_server"; then
# 	exit 1
# fi
