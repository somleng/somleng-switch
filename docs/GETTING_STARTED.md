# Getting Started

Follow instructions below to get Somleng (Adhearsion) up and running on your local machine.

## Install and run FreeSWITCH

Run the [FreeSWITCH](https://github.com/somleng/freeswitch-config/blob/master/docs/GETTING_STARTED.md) docker image optimized for Somleng.

## Run the Somleng (Adhearsion) docker image

```
$ sudo docker run -d --rm --name ahn-somleng -e AHN_CORE_HTTP_ENABLE=false -e AHN_CORE_HOST=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(sudo docker ps -qf "name=fs-somleng")) -e AHN_CORE_PASSWORD=secret -e AHN_CORE_USERNAME=adhearsion@localhost -e AHN_ADHEARSION_DRB_PORT=9050 dwilkie/somleng
```

Note: The environment variables above assume your using the default settings in the [FreeSWITCH configuration](https://github.com/somleng/freeswitch-config)

## Check the logs

```
$ sudo docker logs -f $(sudo docker ps -qf "name=ahn-somleng")
```
