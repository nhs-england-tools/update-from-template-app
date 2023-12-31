# === Builder ==================================================================

# `golang:latest` will be replaced with a specific version stored in ./.tool-versions
FROM golang:latest as builder
WORKDIR /github/workspace
COPY . .
RUN set -ex; \
    \
    CGO_ENABLED=0 GOOS=linux go build \
        -a -installsuffix cgo \
        -o ./build/update-from-template ./cmd/update-from-template/

# === Runtime ==================================================================

# `alpine:latest` will be replaced with a specific version stored in ./.tool-versions
FROM alpine:latest
ENV TZ=Europe/London
RUN set -ex; \
    \
    apk --no-cache add \
        bash \
        coreutils \
        curl \
        git \
        git-lfs \
        github-cli \
        gpg \
        gpg-agent \
        jq \
        openssl \
        tzdata
COPY --from=builder /github/workspace/build/update-from-template /
COPY --from=builder /github/workspace/entrypoint.sh /
COPY --from=builder /github/workspace/gpg.sh /
COPY --from=builder /github/workspace/scripts/config/update-from-template.yaml /update-from-template.yaml
ENTRYPOINT ["/entrypoint.sh"]
