#!/bin/bash

set -euo pipefail

# ==============================================================================

datetime=${BUILD_DATETIME:-$(date -u +"%Y-%m-%dT%H:%M:%S%z")}
build_datetime_local=$(date --date="$datetime" +"%Y-%m-%dT%H:%M:%S%z")
build_datetime=$datetime
build_timestamp=$(date --date="$datetime" -u +"%Y%m%d%H%M%S")

work_dir=/github/workspace
src_dir=$work_dir/repository-template
dest_dir=$work_dir/repository-to-update
list_of_files_to_update_json=${work_dir}/update-from-template.json

git_user_name=${GIT_USER_NAME:-"unknown"}
git_user_email=${GIT_USER_EMAIL:-"unknown@users.noreply.github.com"}

GH_APP_PK_PATH=$work_dir/gh_app_pk.pem
if ! [ -f $GH_APP_PK_PATH ]; then
  echo "$GH_APP_PK" > $GH_APP_PK_PATH
fi

# ==============================================================================

function main() {

  github_token=$(create-github-token)
  configure-git-access
  fetch-repositories-content
  prune-legacy-updates
  checkout-new-branch
  produce-list-of-files-to-update
  update-files
  push-and-create-pull-request
}

function create-github-token() {

  is-arg-true "$DRY_RUN" && return

  header=$(echo -n '{"alg":"RS256","typ":"JWT"}' | base64 | tr -d '=' | tr -d '\n=' | tr -- '+/' '-_')
  payload=$(echo -n '{"iat":'$(date +%s)',"exp":'$(($(date +%s)+600))',"iss":"'$GH_APP_ID'"}' | base64 | tr -d '\n=' | tr -- '+/' '-_')
  signature=$(echo -n "$header.$payload" | openssl dgst -binary -sha256 -sign $GH_APP_PK_PATH | openssl base64 | tr -d '\n=' | tr -- '+/' '-_')
  jwt="$header.$payload.$signature"

  installations_response=$(curl -X GET \
    -H "Authorization: Bearer $jwt" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/app/installations)
  installation_id=$(echo $installations_response | jq '.[0].id')

  token_response=$(curl -X POST \
    -H "Authorization: Bearer $jwt" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/app/installations/$installation_id/access_tokens)
  github_token=$(echo $token_response | jq .token -r)

  echo "$github_token"
}

function configure-git-access() {

  git config --global user.name "$git_user_name"
  git config --global user.email "$git_user_email"
  git config --global pull.rebase false
  git config --global --add safe.directory $dest_dir

  [ -z "$github_token"] && return
  echo "$github_token" | gh auth login --with-token
  gh auth status
  gh auth setup-git
}

function fetch-repositories-content() {

  mkdir -p $work_dir
  cd $work_dir
  if [ -n "$github_token" ] && ! [ -d $src_dir ] && ! [ -d $dest_dir ]; then
    git clone https://x-access-token:${github_token}@${REPOSITORY_TEMPLATE} $src_dir
    git clone https://x-access-token:${github_token}@${REPOSITORY_TO_UPDATE} $dest_dir
  else
    if ! [ -d $src_dir ]; then
      git clone https://${REPOSITORY_TEMPLATE} $src_dir
    else
      (
        cd $src_dir
        git fetch origin
        default_branch=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
        git reset --hard origin/$default_branch
      )
    fi
    if ! [ -d $dest_dir ]; then
      git clone https://${REPOSITORY_TO_UPDATE} $dest_dir
    else
      (
        cd $dest_dir
        git fetch origin
        default_branch=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
        git reset --hard origin/$default_branch
      )
    fi
  fi
}

function prune-legacy-updates() {

  [ -z "$github_token"] && return

  cd ${dest_dir}
  # Close legacy PRs
  pr_numbers=$(gh pr list --search "Update from template" --json number,title | jq '.[] | select(.title | startswith("Update from template")).number')
  for pr_number in $pr_numbers; do
    gh pr close $pr_number
  done
  # Delete legacy branches
  for branch in $(git branch -r | grep 'origin/update-from-template'); do
    git push origin --delete ${branch#origin/}
  done
}

function checkout-new-branch() {

  cd ${dest_dir}
  git checkout -b update-from-template-${build_timestamp}
}

function produce-list-of-files-to-update() {

  cd ${dest_dir}
  /compare-directories \
    --source-dir ${src_dir} \
    --destination-dir ${dest_dir} \
    --app-config-file /.config.yaml \
    --template-config-file ${dest_dir}/scripts/config/.repository-template.yaml \
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
    mkdir -p ${dest_dir}/$dir
    cp ${src_dir}/$file ${dest_dir}/$file
  done
  # Delete files
  to_delete=$(
    cat $list_of_files_to_update_json \
      | jq -r '.comparison | to_entries[] | select(.value.action == "delete") | .key'
  )
  echo "$to_delete" | while IFS= read -r file; do
    rm -rf ${dest_dir}/$file
  done
}

function push-and-create-pull-request() {

  cd ${dest_dir}
  # Add and commit changes
  git add -A
  git commit -m "Update from template ${build_datetime_local}"

  [ -z "$github_token"] && return

  # Push and create new PR
  git push -u origin update-from-template-${build_timestamp}
  gh pr create \
    --title "Update from template" \
    --body "Update from template ${build_datetime_local}"
}

function is-arg-true() {

  if [[ "$1" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$ ]]; then
    return 0
  else
    return 1
  fi
}

# ==============================================================================

is-arg-true "${VERBOSE:-false}" && set -x

main $*

exit 0
