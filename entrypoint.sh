#!/bin/sh -l

/compare-directories \
  --source-dir $1 \
  --destination-dir $2 \
  --app-config-file /.config.yaml \
  --template-config-file $2/scripts/config/.repository-template.yaml \
> ./output.json
cat ./output.json

set -x
to_update=$(
  cat ./output.json \
    | jq -r '.comparison | to_entries[] | select(.value.action == "update") | .key'
)
echo "$to_update" | while IFS= read -r file; do
  dir=$(dirname "$file")
  mkdir -p $2/$dir
  cp $1/$file $2/$file
done

to_delete=$(
  cat ./output.json \
    | jq -r '.comparison | to_entries[] | select(.value.action == "delete") | .key'
)
echo "$to_delete" | while IFS= read -r file; do
  rm -rf $2/$file
done
