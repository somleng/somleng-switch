#!/bin/sh

set -e

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
AWS_PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
DESTINATION_NUMBER="1234"
HOSTNAME=$(cat /etc/hostname)

read -p "1. Add (or modify) a SIP trunk on Somleng with the following Source IP for Inbound Dialing: $AWS_PUBLIC_IP. Press any key when done."
read -p "2. Configure the number: $DESTINATION_NUMBER on Somleng: Press any key when done."
read -p "3. Start TCP dump. In another terminal run the following: sudo docker run -it --rm --net container:$HOSTNAME nicolaka/netshoot followed by tcpdump -Xvv -i eth0 -s0 -w capture.pcap. Press any key when done."

log_file="uac_*_messages.log"
rm -f $log_file

sipp -sf scenarios/uac.xml 15.197.218.231:5080 -key username "+855715100850" -s 1234 -m 1 -trace_msg > /dev/null
