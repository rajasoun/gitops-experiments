FROM alpine:latest

RUN apk add --no-cache ca-certificates curl bash tar jq yq

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
USER 1001
ENTRYPOINT ["/entrypoint.sh"]
