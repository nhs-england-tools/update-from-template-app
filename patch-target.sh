#!/bin/bash

set -euo pipefail

src_dir=$1
dest_dir=$2
list_of_files_to_update_json=$3

function produce-list-of-files-to-update() {

  cd $dest_dir
  /update-from-template \
    --source-dir $src_dir \
    --destination-dir $dest_dir \
    --app-config-file /.config.yaml \
    --template-config-file $dest_dir/scripts/config/.repository-template.yaml \
  > $list_of_files_to_update_json
}

function update-files() {

  # Update files
  to_update=$(
    cat $list_of_files_to_update_json \
      | jq -r '.comparison | to_entries[] | select(.value.action == "update") | .key'
  )
  echo "$to_update" | while IFS= read -r file; do
    dir=$(dirname "$file")
    mkdir -p $dest_dir/$dir
    cp $src_dir/$file $dest_dir/$file
  done
  # Delete files
  to_delete=$(
    cat $list_of_files_to_update_json \
      | jq -r '.comparison | to_entries[] | select(.value.action == "delete") | .key'
  )
  echo "$to_delete" | while IFS= read -r file; do
    rm -rf $dest_dir/$file
  done
}

function commit-changes() {

  cd $dest_di}
  # Add and commit changes
  git add -A
  git commit -m "Update from template ${build_datetime_local}"

}

main $*
exit 0
