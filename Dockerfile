# === Builder ==================================================================

# `golang:latest` will be replaced with a specific version stored in ./.tool-versions
FROM golang:latest as builder
WORKDIR ${GITHUB_WORKSPACE:-/github/workspace}
COPY . .
RUN set -ex; \
    \
    CGO_ENABLED=0 GOOS=linux go build \
        -a -installsuffix cgo \
        -o ./build/compare-directories ./cmd/compare-directories/

# === Runtime ==================================================================

# `alpine:latest` will be replaced with a specific version stored in ./.tool-versions
FROM alpine:latest
RUN set -ex; \
    \
    apk --no-cache add \
        curl \
        git \
        git-lfs \
        github-cli \
        jq
COPY --from=builder ${GITHUB_WORKSPACE:-/github/workspace}/entrypoint.sh /
COPY --from=builder ${GITHUB_WORKSPACE:-/github/workspace}/build/compare-directories /
COPY --from=builder ${GITHUB_WORKSPACE:-/github/workspace}/scripts/config/.update-from-template.yaml /.config.yaml
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
