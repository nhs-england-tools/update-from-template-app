#!/bin/bash

set -eu

cd $(dirname "$(readlink -f "$0")")

cidfile=.cid
docker stop $(cat "$cidfile" 2> /dev/null) > /dev/null 2>&1
rm -rf "$cidfile"
