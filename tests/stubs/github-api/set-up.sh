#!/bin/bash

set -eu

cd $(dirname "$(readlink -f "$0")")

image=wiremock/wiremock:3.1.0-alpine # TODO: Move the image version to the .tool-versions file
cidfile=.cid
docker run --rm --platform linux/amd64 \
  --cidfile "$cidfile" \
  --volume "$PWD:/home/wiremock" \
  --publish 8080:8080 \
  $image \
  > /dev/null 2>&1 &
