#!/bin/bash

set -euo pipefail

function usage() {
    cat <<USAGE
Usage: ${0} <source-dir> <target-dir> <commit-message>

Commits a patch to <target-dir> with the relevant changes from
<source-dir> and the given <commit-message>, and outputs a JSON
document with the files that were changed.

Environment variables

\$UPDATE_BINARY: Set this to the path of the update-from-template
  executable.  Defaults to '/update-from-template'.  Currently set to
  '${update_binary}'.

\$UPDATE_CONFIG_FILE: Set this to the path of the config file for
  the update-from-template executable.  Defaults to '/.config.yaml'.
  Currently set to '${update_config_file}'.

USAGE
}

src_dir=${1:-}
dest_dir=${2:-}
commit_msg=${3:-}
update_binary=${UPDATE_BINARY:-/update-from-template}
update_config_file=${UPDATE_CONFIG_FILE:-/.config.yaml}


# If we only rely on `set -u` for our error handling, we don't get
# very descriptive error output.  This gives us a chance to be more
# helpful.
# use echo "failure message" | fail
function fail() {
    cat >&2
    echo >&2
    usage >&2
    exit 1
}

[ -z "${src_dir}" ] && echo "No source or target directory given" | fail
[ -z "${dest_dir}" ] && echo "No target directory given" | fail
[ -z "$commit_msg" ] && echo "No commit message given." | fail
[ -z "$update_binary" ] && echo "\$UPDATE_BINARY is set to the empty string" | fail
[ ! -e $update_binary ] && echo "$update_binary does not exist. Please set \$UPDATE_BINARY." | fail
[ ! -x $update_binary ] && echo "$update_binary is not executable" | fail
[ ! -d $src_dir ] && echo "Source directory $src_dir does not exist." | fail
[ ! -d $dest_dir ] && echo "Target directory $dest_dir does not exist." | fail
[ ! -d "$src_dir/.git" ] && echo "$src_dir is not a git working tree." | fail
[ ! -d "$dest_dir/.git" ] && echo "$dest_dir is not a git working tree." | fail

temp_dir=$(mktemp -d)
trap "rm -r ${temp_dir}" EXIT

list_of_files_to_update_json=$temp_dir/update-from-template.json

function main() {
    produce-list-of-files-to-update
    update-files
    commit-changes
    cat $list_of_files_to_update_json
}

function produce-list-of-files-to-update() {

#  cd $dest_dir
  $update_binary \
    --source-dir $src_dir \
    --destination-dir $dest_dir \
    --app-config-file $update_config_file \
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
    if [ ! -z "$file" ]; then rm -r $dest_dir/$file; fi
  done
}

function commit-changes() {

  cd $dest_dir
  # Add and commit changes
  git add -A
  git commit -m "${commit_msg}"

}

main $*
exit 0
