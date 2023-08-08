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
