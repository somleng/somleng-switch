FROM alpine:latest

RUN apk update && apk upgrade && apk add --update --no-cache sipp

COPY scenarios/ scenarios/
COPY tests/ tests/
COPY tests.sh tests.sh

WORKDIR /tmp
