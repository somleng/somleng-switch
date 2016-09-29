# Somleng

[![Build Status](https://travis-ci.org/dwilkie/somleng.svg?branch=master)](https://travis-ci.org/dwilkie/somleng)

Somleng (សំឡេង meaning Voice in Khmer) is an Adhearsion application compatible with [Twilreapi](https://github.com/dwilkie/twilreapi) and [TwiML](https://www.twilio.com/docs/api/twiml). It can be used, for certain call flows, as a drop-in replacement for Twilio routing calls to a local telco a SIP provider.

## Compatibilty

Currently Somleng only supports [FreeSwitch](https://freeswitch.org/). Theoretically [Asterisk](http://www.asterisk.org/) should also work but it has not been tested.

## Configuration

Run the following rake task to show the adhearsion configuration

```
$ bundle exec rake config:show
```

### FreeSwitch Configuration

To get started we recommend using the FreeSwitch configuration available [here](https://github.com/dwilkie/freeswitch-config).

## Deployment

### Heroku

For testing purposes we recommend deploying to Heroku.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

### Elastic Beanstalk

#### Disk I/O

When load testing on AWS you'll hit likely hit a disk I/O limitation. This limitation will show up as an `iowait` issue in the CPU usage. This [troubleshooting guide](http://bencane.com/2012/08/06/troubleshooting-high-io-wait-in-linux/) has more info on how to debug the issue.

To debug you'll need to install `iostat` and `iotop` which can be installed io your elastic beanstalk instance with the following command.

```
sudo yum install iotop sysstat
```

When this happens on an Elastic Beanstalk instance running docker, the environment will go into warning state, and eventually the docker daemon restarts Adhearsion and all your active calls will be lost.

Reading through the [EBS performance article](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSPerformance.html) suggests to increase the Read-Ahead for Read-Heavy workloads.

```
sudo blockdev --report /dev/xvdcz
sudo blockdev --setra 2048 /dev/xvdcz
```

You can also set up [CloudWatch alarms](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-volume-status.html) for various ELB metrics.

## License

The software is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
