FROM alpine:latest
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENV FIFO_NAME "/tmp/opensips_fifo"

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["opensips_scheduler"]
