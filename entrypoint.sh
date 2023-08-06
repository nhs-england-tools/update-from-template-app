#!/bin/sh -l

/compare-directories \
  --source-dir $1 \
  --destination-dir $2 \
  --config-file $3
> ./output.json
cat ./output.json

set -x

to_copy=$(
  cat ./output.json \
    | jq -r '.comparison | to_entries[] | select(.value.action == "copy") | .key'
)
for file in $to_copy; do
  dir=$(dirname "$file")
  mkdir -p $2/$dir
  cp $1/$file $2/$file
done

to_delete=$(
  cat ./output.json \
    | jq -r '.comparison | to_entries[] | select(.value.action == "delete") | .key'
)
for file in $to_delete; do
  rm -rf $2/$file
done
