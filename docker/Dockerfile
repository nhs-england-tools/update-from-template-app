FROM alpine:3.18.2

RUN set -ex; \
    \
    apk --no-cache add \
        jq=1.6-r3

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# === Metadata =================================================================

ARG IMAGE
ARG TITLE
ARG DESCRIPTION
ARG LICENCE
ARG GIT_URL
ARG GIT_BRANCH
ARG GIT_COMMIT_HASH
ARG BUILD_DATE
ARG BUILD_VERSION
LABEL \
    org.opencontainers.image.base.name=$IMAGE \
    org.opencontainers.image.title="$TITLE" \
    org.opencontainers.image.description="$DESCRIPTION" \
    org.opencontainers.image.licenses="$LICENCE" \
    org.opencontainers.image.url=$GIT_URL \
    org.opencontainers.image.ref.name=$GIT_BRANCH \
    org.opencontainers.image.revision=$GIT_COMMIT_HASH \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.version=$BUILD_VERSION
