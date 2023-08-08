#!/bin/bash

set -euo pipefail

# Required variables:
#   DOCKER_IMAGE=ghcr.io/repo/name
#   DOCKER_TITLE="My Docker image"

# ==============================================================================

# Build Docker image
# Arguments:
#   dir=[path to the Dockerfile to use; default is '.']
function docker-build() {

  dir=${dir:-$PWD}
  _create-effective-dockerfile
  _create-effective-version
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
    --build-arg BUILD_VERSION=$(cat ${dir}/.version) \
    --tag ${DOCKER_IMAGE}:$(cat ${dir}/.version) \
    --rm \
    --file ${dir}/Dockerfile.effective \
    .
  docker tag ${DOCKER_IMAGE}:$(cat ${dir}/.version) ${DOCKER_IMAGE}:latest
  docker rmi --force $(docker images | grep "<none>" | awk '{ print $3 }') 2> /dev/null ||:
}

# Test Docker image
# Arguments:
#   output=[output string to search for]
#   dir=[path to the Dockerfile to use; default is '.']
function docker-test() {

  dir=${dir:-$PWD}
  docker run --rm \
    ${DOCKER_IMAGE}:$(cat ${dir}/.version) 2>/dev/null \
  | grep -q "${output}" && echo PASS || echo FAIL
}

# Run Docker image
# Arguments:
#   args=[arguments to pass to Docker to run the container; default is none/empty]
#   cmd=[command to pass to the container for execution; default is none/empty]
#   dir=[path to the Dockerfile to use; default is '.']
function docker-run() {

  dir=${dir:-$PWD}
  docker run --rm \
    ${args:-} \
    ${DOCKER_IMAGE}:$(cat ${dir}/.version) \
    ${cmd:-}
}

# Push Docker image
# Arguments:
#   dir=[path to the Dockerfile to use; default is '.']
function docker-push() {

  dir=${dir:-$PWD}
  docker push ${DOCKER_IMAGE}:$(cat ${dir}/.version)
  docker push ${DOCKER_IMAGE}:latest
}

# Remove Docker resources
# Arguments:
#   dir=[path to the Dockerfile to use; default is '.']
function docker-clean() {

  dir=${dir:-$PWD}
  find ${dir} -type f -name 'Dockerfile.effective' | xargs rm -f
  docker rmi ${DOCKER_IMAGE}:$(cat ${dir}/.version) > /dev/null 2>&1 ||:
  docker rmi ${DOCKER_IMAGE}:latest > /dev/null 2>&1 ||:
}

# ==============================================================================

# Create effective Dockerfile
# Arguments:
#   dir=[path to the Dockerfile to use; default is '.']
function _create-effective-dockerfile() {

  dir=${dir:-$PWD}
  cp ${dir}/Dockerfile ${dir}/Dockerfile.effective
  _replace-image-latest-by-specific-version
  _append-metadata
}

# Replace image:latest by a specific version
# Arguments:
#   dir=[path to the Dockerfile to use; default is '.']
function _replace-image-latest-by-specific-version() {

  dir=${dir:-$PWD}
  versions_file=$(git rev-parse --show-toplevel)/.tool-versions
  if [ -f $versions_file ]; then
    cat $versions_file | while IFS= read -r line; do
      [ -z "$line" ] && continue
      line=$(echo "$line" | sed 's/^#\s*//; s/\s*#.*$//')
      name=$(echo "$line" | awk '{print $1}')
      version=$(echo "$line" | awk '{print $2}')
      sed -i "s/FROM ${name}:latest/FROM ${name}:${version}/g" ${dir}/Dockerfile.effective
    done
  fi
}

# Append metadata to the end of Dockerfile
# Arguments:
#   dir=[path to the Dockerfile to use; default is '.']
function _append-metadata() {

  dir=${dir:-$PWD}
  cat \
    $dir/Dockerfile.effective \
    $(git rev-parse --show-toplevel)/scripts/docker/Dockerfile.metadata \
  > $dir/Dockerfile.effective.tmp
  mv $dir/Dockerfile.effective.tmp $dir/Dockerfile.effective
}

# Create effective version from the VERSION file
# Arguments:
#   dir=[path to the Dockerfile to use; default is '.']
function _create-effective-version() {

  dir=${dir:-$PWD}
  build_datetime=${BUILD_DATETIME:-$(date -u +'%Y-%m-%dT%H:%M:%S%z')}
  if [ -f $dir/VERSION ]; then
    cat $dir/VERSION | \
      sed "s/yyyy/$(date --date=${build_datetime} -u +"%Y")/g" | \
      sed "s/mm/$(date --date=${build_datetime} -u +"%m")/g" | \
      sed "s/dd/$(date --date=${build_datetime} -u +"%d")/g" | \
      sed "s/HH/$(date --date=${build_datetime} -u +"%H")/g" | \
      sed "s/MM/$(date --date=${build_datetime} -u +"%M")/g" | \
      sed "s/SS/$(date --date=${build_datetime} -u +"%S")/g" | \
      sed "s/hash/$(git rev-parse --short HEAD)/g" \
    > $dir/.version
  fi
}
