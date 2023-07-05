#!/bin/sh -l

pwd
ls -la

echo "Hello $1"
time=$(date)
echo "time=$time" >> ${GITHUB_OUTPUT:-/dev/stdout}
