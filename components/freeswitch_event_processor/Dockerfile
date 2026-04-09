FROM public.ecr.aws/docker/library/golang:alpine AS builder
WORKDIR /app
COPY . ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w" .

FROM public.ecr.aws/docker/library/golang:alpine
WORKDIR /app
COPY --from=builder /app/freeswitch_event_processor /app
ENTRYPOINT [ "/app/freeswitch_event_processor" ]
