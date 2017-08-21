# Somleng

[![Build Status](https://travis-ci.org/somleng/somleng.svg?branch=master)](https://travis-ci.org/somleng/somleng)
[![Test Coverage](https://codeclimate.com/github/somleng/somleng/badges/coverage.svg)](https://codeclimate.com/github/somleng/somleng/coverage)

Somleng (សំឡេង meaning Voice in Khmer) is an Adhearsion application compatible with [Twilreapi](https://github.com/dwilkie/twilreapi) and [TwiML](https://www.twilio.com/docs/api/twiml). It can be used, for certain call flows, as a drop-in replacement for Twilio routing calls to a local telco a SIP provider.

## Compatibilty

Currently Somleng only supports [FreeSwitch](https://freeswitch.org/). Theoretically [Asterisk](http://www.asterisk.org/) should also work but it has not been tested.

## Configuration

Run the following rake task to show the adhearsion configuration

```
$ bundle exec rake config:show
```

### FreeSwitch Configuration

To get started we recommend using the FreeSwitch configuration available [here](https://github.com/somleng/freeswitch-config).

## Deployment

See [DEPLOYMENT](https://github.com/somleng/somleng/tree/master/docs/DEPLOYMENT.md)

## License

The software is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
