FROM public.ecr.aws/docker/library/alpine:latest

RUN apk update && apk upgrade && apk add --update --no-cache jq python3 sipp curl postgresql-client bind-tools nodejs npm tshark sox ffmpeg tcpdump

WORKDIR /testing

COPY --link . .

RUN cd /testing/support/ws_server && \
    npm install

EXPOSE 5060

ENV WS_SERVER_PORT "3001"
ENV FILE_SERVER_PORT "8000"

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["services"]
