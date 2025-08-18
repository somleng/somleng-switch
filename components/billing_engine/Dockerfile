FROM public.ecr.aws/docker/library/golang:alpine AS builder

RUN apk add --no-cache git build-base bash

# Set up work directory according to GOPATH
WORKDIR /go/src/github.com/cgrates/cgrates

# Clone CGRateS source
RUN git clone https://github.com/cgrates/cgrates.git .

# Build CGRateS using official build.sh script
RUN chmod +x build.sh && ./build.sh

FROM public.ecr.aws/docker/library/golang:alpine

RUN apk add --no-cache bash ca-certificates postgresql-client

# Copy CGRateS binaries
COPY --from=builder /go/bin/cgr-engine /usr/bin/cgr-engine
COPY --from=builder /go/bin/cgr-loader /usr/bin/cgr-loader
COPY --from=builder /go/bin/cgr-migrator /usr/bin/cgr-migrator
COPY --from=builder /go/bin/cgr-console /usr/bin/cgr-console
COPY --from=builder /go/bin/cgr-tester /usr/bin/cgr-tester

# Copy data directory
COPY --from=builder /go/src/github.com/cgrates/cgrates/data /usr/share/cgrates
# RUN sed -i 's/\bsudo\b//g' /usr/share/cgrates/storage/postgres/*.sh
RUN mkdir -p /etc/cgrates

# Add entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Run as non-root
RUN adduser -D -u 1000 cgrates
RUN chown cgrates:cgrates /etc/cgrates
USER cgrates
WORKDIR /home/cgrates

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
