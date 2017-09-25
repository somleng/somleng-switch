# Getting Started

Follow instructions below to get Somleng (Adhearsion) up and running on your local machine.

## Install and run FreeSWITCH

To get started we recommend using the FreeSWITCH configuration available [here](https://github.com/somleng/freeswitch-config).

Follow the [GETTING STARTED guide for FreeSWITCH](https://github.com/somleng/freeswitch-config/blob/master/docs/GETTING_STARTED.md) to get FreeSWITCH up and running first.

## Run the Somleng (Adhearsion) docker image

```
$ sudo docker run -d --rm --name ahn-somleng -e AHN_CORE_HTTP_ENABLE=false -e AHN_CORE_HOST=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(sudo docker ps -qf "name=fs-somleng")) -e AHN_CORE_PASSWORD=secret -e AHN_CORE_USERNAME=adhearsion@localhost -e AHN_ADHEARSION_DRB_PORT=9050 dwilkie/somleng
```

Note: The environment variables above assume your using the default settings in the [FreeSWITCH configuration](https://github.com/somleng/freeswitch-config)

## Check the logs

```
$ sudo docker logs -f $(sudo docker ps -qf "name=ahn-somleng")
```

## Show the available configuration

Run the following rake task to show the adhearsion configuration

```
$ sudo docker run --rm dwilkie/somleng bundle exec rake config:show
```
