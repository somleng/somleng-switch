FROM alpine:latest
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY opensips_scheduler.sh /usr/local/bin/opensips_scheduler

ENV FIFO_NAME "/var/opensips/opensips_fifo"

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["opensips_scheduler"]
