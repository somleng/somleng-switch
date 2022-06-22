FROM golang:alpine AS builder
WORKDIR /app
COPY . ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w" .

FROM scratch
WORKDIR /app
COPY --from=builder /app/freeswitch_event_logger /usr/bin
ENTRYPOINT [ "freeswitch_event_logger" ]
