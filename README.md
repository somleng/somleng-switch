# SomlengSWITCH

[![Build](https://github.com/somleng/somleng-switch/actions/workflows/build.yml/badge.svg)](https://github.com/somleng/somleng-switch/actions/workflows/build.yml)
[![View performance data on Skylight](https://badges.skylight.io/status/Z5dVwBwcpWaW.svg)](https://oss.skylight.io/app/applications/Z5dVwBwcpWaW)
[![Codacy Badge](https://app.codacy.com/project/badge/Coverage/db2c6093e37746599a9d5c1b5b703715)](https://www.codacy.com/gh/somleng/somleng-switch/dashboard?utm_source=github.com&utm_medium=referral&utm_content=somleng/somleng-switch&utm_campaign=Badge_Coverage)

SomlengSWITCH contains an open source [TwiML](https://www.twilio.com/docs/api/twiml) parser, [FreeSWITCH](https://freeswitch.com/) configuration and related infrastructure. It's a dependency of [Somleng](https://github.com/somleng/somleng) and is used to programmatically control phone calls through FreeSWITCH.

## Usage

In order to get the full Somleng stack up and running on your development machine, please follow the [GETTING STARTED](https://github.com/somleng/somleng-project/blob/master/docs/GETTING_STARTED.md) guide.

## Deployment

The [infrastructure directory](https://github.com/somleng/somleng-switch/tree/develop/infrastructure) contains [Terraform](https://www.terraform.io/) configuration files in order to deploy SomlengSWITCH to AWS.

:warning: The current infrastructure of Somleng is rapidly changing as we continue to improve and experiment with new features. We often make breaking changes to the current infrastructure which usually requires some manual migration. We don't recommend that you try to deploy and run your own Somleng stack for production purposes at this stage.

The infrastructure in this repository depends on some shared core infrastructure. This core infrastructure can be found in the [Somleng Project](https://github.com/somleng/somleng-project/tree/master/infrastructure) repository.

The current infrastructure deploys SomlengSWITCH to AWS behind an Network Load Balancer (NLB) to Elastic Container Service (ECS). There is one task, which runs three containers. An [NGINX container](https://github.com/somleng/somleng-switch/blob/develop/docker/nginx/Dockerfile) which runs as a reverse proxy to the [Adhearsion container](https://github.com/somleng/somleng-switch/blob/develop/Dockerfile) which accepts API requests from Somleng. There's also a [FreeSWITCH container](https://github.com/somleng/somleng-switch/blob/develop/docker/freeswitch/Dockerfile) which handles SIP connections to operators.

## License

The software is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
