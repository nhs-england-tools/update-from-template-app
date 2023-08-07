#!/bin/bash

set -euo pipefail

# Required variables:
#   DOCKER_IMAGE=ghcr.io/repo/name
#   DOCKER_TITLE="My Docker image"

# ==============================================================================

# Build Docker image - optional: dir=[path to the Dockerfile to use; default is '.']
function docker-build() {

  cp ${dir}/Dockerfile ${dir}/Dockerfile.effective
  cat .tool-versions | while IFS= read -r line; do
    [ -z "$line" ] && continue
    line=$(echo "$line" | sed 's/^#\s*//; s/\s*#.*$//')
    name=$(echo "$line" | awk '{print $1}')
    version=$(echo "$line" | awk '{print $2}')
    sed -i "s/FROM ${name}:latest/FROM ${name}:${version}/g" ${dir}/Dockerfile.effective
  done
  docker build \
    --progress=plain \
    --build-arg IMAGE=${DOCKER_IMAGE} \
    --build-arg TITLE="${DOCKER_TITLE}" \
    --build-arg DESCRIPTION="${DOCKER_TITLE}" \
    --build-arg LICENCE=MIT \
    --build-arg GIT_URL=$(git config --get remote.origin.url) \
    --build-arg GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD) \
    --build-arg GIT_COMMIT_HASH=$(git rev-parse --short HEAD) \
    --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%S%z') \
    --build-arg BUILD_VERSION=$(cat VERSION) \
    --tag ${DOCKER_IMAGE}:$(cat VERSION) \
    --rm \
    --file ${dir}/Dockerfile.effective \
    .
  docker tag ${DOCKER_IMAGE}:$(cat VERSION) ${DOCKER_IMAGE}:latest
  docker rmi --force $(docker images | grep "<none>" | awk '{ print $3 }') 2> /dev/null ||:
}

# Test Docker image - mandatory: output=[output string to search for]
function docker-test() {

  docker run --rm ${DOCKER_IMAGE}:$(cat VERSION) 2>/dev/null \
    | grep -q "${output}" && echo PASS || echo FAIL
}

# Run Docker image - mandatory: args=[command-line arguments to pass to the container]
function docker-run() {

  docker run --rm \
    --volume ${PWD}/tests:/tests \
    ${DOCKER_IMAGE}:$(cat VERSION) \
    ${args}
}

# Remove Docker resources - optional: dir=[directory to work within; default is '.']
function docker-clean() {

  find ${dir:-$PWD} -type f -name 'Dockerfile.effective' | xargs rm -f
  docker rmi ${DOCKER_IMAGE}:$(cat VERSION) > /dev/null 2>&1 ||:
  docker rmi ${DOCKER_IMAGE}:latest > /dev/null 2>&1 ||:
}

# Push Docker image
function docker-push() {

  docker push ${DOCKER_IMAGE}:$(cat VERSION)
  docker push ${DOCKER_IMAGE}:latest
}
