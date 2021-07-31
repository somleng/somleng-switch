# Getting Started

This is the getting started guide for Somleng's FreeSWITCH config. If you want to get the full Somleng stack up and running see the [getting started guide for Somleng](https://github.com/somleng/somleng-project/blob/master/docs/GETTING_STARTED.md).

Follow instructions below to get FreeSWITCH up and running on your local machine.

## Pull and run the image

```
$ docker run --rm --name fs-somleng -d -p 5060:5060/udp dwilkie/freeswitch-rayo
```

## Check the container is running

```
$ docker ps -f "name=fs-somleng"
```

## Run fs_cli (optional)

```
$ docker run --rm -it dwilkie/freeswitch-rayo fs_cli -H $(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -qf "name=fs-somleng"))
```
