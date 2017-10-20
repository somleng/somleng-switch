# Getting Started

This is the getting started guide for Somleng-Adhearsion. Follow instructions below to get Somleng-Adhearsion up and running on your local machine. If you want to get the full Somleng stack up and running see the [getting started guide for Somleng](https://github.com/somleng/somleng-project/blob/master/docs/GETTING_STARTED.md).

## Pull the latest images

```
$ sudo docker-compose pull
```

## Run the Somleng-Adhearsion docker image

```
$ sudo docker-compose up
```

## Show the available configuration (optional)

Run the following rake task to show the adhearsion configuration

```
$ sudo docker run --rm dwilkie/somleng:spec bundle exec rake config:show
```
