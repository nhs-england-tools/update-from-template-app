FROM alpine:3.18.2

RUN set -ex; \
    \
    apk --no-cache add \
        jq=1.6-r3

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# === Metadata =================================================================

# ARG IMAGE
# ARG BUILD_DATE
# ARG BUILD_VERSION
# ARG GIT_URL
# ARG GIT_BRANCH
# ARG GIT_COMMIT_HASH
