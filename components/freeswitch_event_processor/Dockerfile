FROM public.ecr.aws/docker/library/golang:alpine AS builder
WORKDIR /app
COPY . ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w" .

FROM public.ecr.aws/docker/library/golang:alpine

RUN apk add --no-cache ca-certificates && update-ca-certificates

WORKDIR /app
COPY --from=builder /app/freeswitch_event_processor /app

ENV HEALTHCHECK_PORT=8080

HEALTHCHECK --interval=10s --timeout=5s --retries=10 \
  CMD wget --server-response --spider --quiet http://127.0.0.1:${HEALTHCHECK_PORT}/health 2>&1 | grep "200 OK" > /dev/null

ENTRYPOINT [ "/app/freeswitch_event_processor" ]
