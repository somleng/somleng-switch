#!/bin/bash -x

sudo apt-get -y update
sudo apt-get install -y xz-utils devscripts cowbuilder git
sudo echo "ALLOWUNTRUSTED=yes" >> /etc/pbuilderrc

sudo mkdir -p /usr/src/freeswitch-debs
sudo git clone https://github.com/somleng/freeswitch.git -bbuild_deps /usr/src/freeswitch-debs/freeswitch

# sudo git clone https://github.com/freeswitch/spandsp.git /usr/src/freeswitch-debs/spandsp
# sudo git clone https://github.com/freeswitch/sofia-sip /usr/src/freeswitch-debs/sofia-sip
#
# Follow this article to build debs
# https://earthly.dev/blog/creating-and-hosting-your-own-deb-packages-and-apt-repo/

# Copy debs to s3 and sign

cd /usr/src/freeswitch-debs/freeswitch

sudo ./debian/util.sh build-all -cbullseye -mquicktest -aarm64

# https://earthly.dev/blog/creating-and-hosting-your-own-deb-packages-and-apt-repo/
