FROM public.ecr.aws/debian/alpine:latest

RUN apk update && apk upgrade && apk add --update --no-cache sipp curl postgresql-client bind-tools

COPY scenarios/ scenarios/
COPY tests/ tests/
COPY tests.sh tests.sh

WORKDIR /workspace

EXPOSE 5060
