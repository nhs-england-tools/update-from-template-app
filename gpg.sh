#!/bin/bash

set -euo pipefail

gpg --batch --pinentry-mode=loopback --passphrase $GITHUB_APP_SK_PASSPHRASE $@
