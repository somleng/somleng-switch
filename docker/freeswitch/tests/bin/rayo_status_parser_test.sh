#!/bin/sh

echo "Running: $(basename $0)"

current_dir=$(dirname "$(readlink -f "$0")")
rayo_status_parser=$current_dir/../bin/rayo_status_parser

cat <<-EOT | $rayo_status_parser
	ENTITIES
      TYPE='COMPONENT_CALL',SUBTYPE='output',ID='746031d5-a831-4053-af6e-ffb3626c8291@rayo.somleng.org/output-1',JID='746031d5-a831-4053-af6e-ffb3626c8291@rayo.somleng.org/output-1',DOMAIN='rayo.somleng.org',REFS=1
      TYPE='CALL',SUBTYPE='',ID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8',JID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org',DOMAIN='rayo.somleng.org',REFS=4
      TYPE='COMPONENT_CALL',SUBTYPE='prompt',ID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org/prompt-2',JID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org/prompt-2',DOMAIN='rayo.somleng.org',REFS=1
      TYPE='CLIENT',SUBTYPE='',ID='ac074fec-15fb-4b2e-be76-521b6cb1bf95@rayo.somleng.org/console',JID='ac074fec-15fb-4b2e-be76-521b6cb1bf95@rayo.somleng.org/console',DOMAIN='rayo.somleng.org',REFS=1,STATUS='OFFLINE'
      TYPE='COMPONENT_CALL',SUBTYPE='input',ID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org/input-4',JID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org/input-4',DOMAIN='rayo.somleng.org',REFS=1
      TYPE='CALL',SUBTYPE='',ID='746031d5-a831-4053-af6e-ffb3626c8291',JID='746031d5-a831-4053-af6e-ffb3626c8291@rayo.somleng.org',DOMAIN='rayo.somleng.org',REFS=2
      TYPE='CLIENT',SUBTYPE='',ID='rayo@rayo.somleng.org/ip-10-10-1-104.ap-southeast-1.compute.internal-1',JID='rayo@rayo.somleng.org/ip-10-10-1-104.ap-southeast-1.compute.internal-1',DOMAIN='rayo.somleng.org',REFS=1,STATUS='ONLINE'
      TYPE='COMPONENT_CALL',SUBTYPE='output',ID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org/output-3',JID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org/output-3',DOMAIN='rayo.somleng.org',REFS=1
      TYPE='SERVER',SUBTYPE='',ID='rayo.somleng.org',JID='rayo.somleng.org',DOMAIN='rayo.somleng.org',REFS=1

	ACTIVE STREAMS
      TYPE='c2s_in',ID='5529094a-bb25-4b60-b636-f59cb2ffdbf3',JID='rayo@rayo.somleng.org/ip-10-10-1-104.ap-southeast-1.compute.internal-1',REMOTE_ADDRESS='127.0.0.1',REMOTE_PORT=59164,STATE='READY'
EOT

if [ $? -ne 0 ]; then
  echo "Expected to find ACTIVE STREAMS with STATE 'READY' but got none"
  exit 1
fi

cat <<-EOT | $rayo_status_parser
	ENTITIES
      TYPE='COMPONENT_CALL',SUBTYPE='output',ID='746031d5-a831-4053-af6e-ffb3626c8291@rayo.somleng.org/output-1',JID='746031d5-a831-4053-af6e-ffb3626c8291@rayo.somleng.org/output-1',DOMAIN='rayo.somleng.org',REFS=1
      TYPE='CALL',SUBTYPE='',ID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8',JID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org',DOMAIN='rayo.somleng.org',REFS=4
      TYPE='COMPONENT_CALL',SUBTYPE='prompt',ID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org/prompt-2',JID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org/prompt-2',DOMAIN='rayo.somleng.org',REFS=1
      TYPE='CLIENT',SUBTYPE='',ID='ac074fec-15fb-4b2e-be76-521b6cb1bf95@rayo.somleng.org/console',JID='ac074fec-15fb-4b2e-be76-521b6cb1bf95@rayo.somleng.org/console',DOMAIN='rayo.somleng.org',REFS=1,STATUS='OFFLINE'
      TYPE='COMPONENT_CALL',SUBTYPE='input',ID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org/input-4',JID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org/input-4',DOMAIN='rayo.somleng.org',REFS=1
      TYPE='CALL',SUBTYPE='',ID='746031d5-a831-4053-af6e-ffb3626c8291',JID='746031d5-a831-4053-af6e-ffb3626c8291@rayo.somleng.org',DOMAIN='rayo.somleng.org',REFS=2
      TYPE='CLIENT',SUBTYPE='',ID='rayo@rayo.somleng.org/ip-10-10-1-104.ap-southeast-1.compute.internal-1',JID='rayo@rayo.somleng.org/ip-10-10-1-104.ap-southeast-1.compute.internal-1',DOMAIN='rayo.somleng.org',REFS=1,STATUS='ONLINE'
      TYPE='COMPONENT_CALL',SUBTYPE='output',ID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org/output-3',JID='bf5c7766-67eb-4b8e-9aa4-03aba9d24da8@rayo.somleng.org/output-3',DOMAIN='rayo.somleng.org',REFS=1
      TYPE='SERVER',SUBTYPE='',ID='rayo.somleng.org',JID='rayo.somleng.org',DOMAIN='rayo.somleng.org',REFS=1

	ACTIVE STREAMS
EOT

if [ $? -eq 0 ]; then
  echo "Expected not to find ACTIVE STREAMS with STATE 'READY' but got one"
  exit 1
fi
