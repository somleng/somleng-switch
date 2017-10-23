# Getting Started

This is the getting started guide for Somleng-Adhearsion. If you want to get the full Somleng stack up and running see the [getting started guide for Somleng](https://github.com/somleng/somleng-project/blob/master/docs/GETTING_STARTED.md).

## Pull the latest images

```
$ docker-compose pull
```

## Run Somleng-Adhearsion

The following command will boot Adhearsion and connect it to FreeSWITCH

```
$ docker-compose up
```

## Show the available configuration (optional)

Run the following rake task to show the configuration for Somleng-Adhearsion

```
$ docker-compose exec adhearsion /bin/bash -c 'bundle exec rake config:show'
```
