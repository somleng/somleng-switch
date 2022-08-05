FROM alpine:latest

RUN apk update && apk upgrade && apk add --update --no-cache sipp curl

COPY scenarios/ scenarios/
COPY fixtures/ fixtures/
COPY tests/ tests/
COPY tests.sh tests.sh

WORKDIR /tmp

EXPOSE 5060
