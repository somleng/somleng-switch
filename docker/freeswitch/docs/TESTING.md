# Testing

## Install SIPp

First install SIPp

```
$ git clone git@github.com:SIPp/sipp.git
$ cd sipp
$ sudo apt-get install libpcap-dev libsctp-dev libgsl-dev
$ ./build.sh
$ sudo make install
```

## Setup sippy_cup

```
$ cd test
$ bundle install --path vendor
```
