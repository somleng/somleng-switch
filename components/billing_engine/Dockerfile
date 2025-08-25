FROM public.ecr.aws/docker/library/golang:alpine AS builder

RUN apk add --no-cache git build-base bash

WORKDIR /go/src/github.com/cgrates/cgrates

# Clone CGRateS source
RUN git clone https://github.com/cgrates/cgrates.git .

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

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN adduser -D -u 1000 cgrates && chown cgrates:cgrates /etc/cgrates
USER cgrates
WORKDIR /home/cgrates

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
