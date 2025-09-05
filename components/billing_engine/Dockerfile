FROM public.ecr.aws/docker/library/golang:alpine AS builder

RUN apk add --no-cache git build-base bash

WORKDIR /go/src/github.com/cgrates/cgrates

# Clone CGRateS source
RUN git clone https://github.com/cgrates/cgrates.git .

# Copy and apply git patch
COPY src/cgrates/fsagent_inbound_filter.patch /tmp/fsagent_inbound_filter.patch
RUN git apply /tmp/fsagent_inbound_filter.patch

# Build CGRateS using official build.sh script
RUN chmod +x build.sh && ./build.sh

FROM public.ecr.aws/docker/library/alpine:latest AS base

RUN apk add --no-cache bash ca-certificates

# Copy CGRateS binaries
COPY --from=builder /go/bin/cgr-engine /usr/bin/cgr-engine
COPY --from=builder /go/bin/cgr-loader /usr/bin/cgr-loader
COPY --from=builder /go/bin/cgr-migrator /usr/bin/cgr-migrator
COPY --from=builder /go/bin/cgr-console /usr/bin/cgr-console
COPY --from=builder /go/bin/cgr-tester /usr/bin/cgr-tester

# Copy data directory
COPY --from=builder /go/src/github.com/cgrates/cgrates/data /usr/share/cgrates
RUN mkdir -p /etc/cgrates

FROM base AS bootstrap

RUN apk add --no-cache postgresql-client

COPY bootstrap.sh /usr/local/bin/bootstrap.sh

ENTRYPOINT ["/usr/local/bin/bootstrap.sh"]

FROM base

RUN apk add --no-cache ngrep

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY docker-healthcheck.sh /usr/local/bin/docker-healthcheck.sh

RUN adduser -D -u 1000 cgrates && chown cgrates:cgrates /etc/cgrates
# USER cgrates
WORKDIR /home/cgrates

ENV HTTP_LISTEN_PORT=2080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD /usr/local/bin/docker-healthcheck.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
