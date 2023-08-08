#!/bin/bash

datetime=${BUILD_DATETIME:-$(date -u +'%Y-%m-%dT%H:%M:%S%z')}
build_datetime_local=$(date --date=${datetime} +'%Y-%m-%dT%H:%M:%S%z')
build_datetime=${datetime}
build_timestamp=$(date --date=${datetime} -u +'%Y%m%d%H%M%S')

git_user_name=${GIT_USER_NAME:-unknown}
git_user_email=${GIT_USER_EMAIL:-unknown@users.noreply.github.com}

work_dir=/github/workspace
src_dir=${work_dir}/repository-template
dest_dir=${work_dir}/repository-to-update

# ==============================================================================

GH_APP_PK_PATH=/github/workspace/gh_app_pk.pem
if ! [ -f $GH_APP_PK_PATH ]; then
  echo "$GH_APP_PK" > $GH_APP_PK_PATH
fi

function generate-jwt() {
  header=$(echo -n '{"alg":"RS256","typ":"JWT"}' | base64 | tr -d '=' | tr -d '\n=' | tr -- '+/' '-_')
  payload=$(echo -n '{"iat":'$(date +%s)',"exp":'$(($(date +%s)+600))',"iss":"'$GH_APP_ID'"}' | base64 | tr -d '\n=' | tr -- '+/' '-_')
  signature=$(echo -n "$header.$payload" | openssl dgst -binary -sha256 -sign $GH_APP_PK_PATH | openssl base64 | tr -d '\n=' | tr -- '+/' '-_')
  echo "$header.$payload.$signature"
}
JWT=$(generate-jwt)

INSTALLATIONS_RESPONSE=$(curl -X GET \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/app/installations)
INSTALLATION_ID=$(echo $INSTALLATIONS_RESPONSE | jq '.[0].id')
TOKEN_RESPONSE=$(curl -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens)
GITHUB_TOKEN=$(echo $TOKEN_RESPONSE | jq .token -r)

echo $GITHUB_TOKEN
gh auth login --with-token <<< $GITHUB_TOKEN
gh auth status
gh auth setup-git

# ==============================================================================

# Global git settings
git config --global user.name "${git_user_name}"
git config --global user.email "${git_user_email}"
git config --global pull.rebase false
git config --global --add safe.directory ${dest_dir}

test -d ${work_dir} || mkdir -p ${work_dir}
cd ${work_dir}
if [ -n "${GITHUB_TOKEN}" ]; then
  git clone https://x-access-token:${GITHUB_TOKEN}@${REPOSITORY_TEMPLATE} ${src_dir}
  git clone https://x-access-token:${GITHUB_TOKEN}@${REPOSITORY_TO_UPDATE} ${dest_dir}
else
  git clone https://${REPOSITORY_TEMPLATE} ${src_dir}
  git clone https://${REPOSITORY_TO_UPDATE} ${dest_dir}
fi

cd ${dest_dir}
if [ -n "${GITHUB_TOKEN}" ]; then
  # Close legacy PRs
  pr_numbers=$(gh pr list --search "Update from template" --json number,title | jq '.[] | select(.title | startswith("Update from template")).number')
  for pr_number in $pr_numbers; do
    gh pr close $pr_number
  done
  # Delete legacy branches
  for branch in $(git branch -r | grep 'origin/update-from-template'); do
    git push origin --delete ${branch#origin/}
  done
fi
# Create new branch
git checkout -b update-from-template-${build_timestamp}

# ==============================================================================

# Produce a list of files to update and delete
/compare-directories \
  --source-dir ${src_dir} \
  --destination-dir ${dest_dir} \
  --app-config-file /.config.yaml \
  --template-config-file ${dest_dir}/scripts/config/.repository-template.yaml \
> ${work_dir}/update-from-template.json
# Update files
to_update=$(
  cat ${work_dir}/update-from-template.json \
    | jq -r '.comparison | to_entries[] | select(.value.action == "update") | .key'
)
echo "$to_update" | while IFS= read -r file; do
  dir=$(dirname "$file")
  mkdir -p ${dest_dir}/$dir
  cp ${src_dir}/$file ${dest_dir}/$file
done
# Delete files
to_delete=$(
  cat ${work_dir}/update-from-template.json \
    | jq -r '.comparison | to_entries[] | select(.value.action == "delete") | .key'
)
echo "$to_delete" | while IFS= read -r file; do
  rm -rf ${dest_dir}/$file
done

# ==============================================================================

cd ${dest_dir}
# Add and commit changes
git add -A
git commit -m "Update from template ${build_datetime_local}"
if [ -n "${GITHUB_TOKEN}" ]; then
  # Push and create new PR
  git push -u origin update-from-template-${build_timestamp}
  gh pr create \
    --title "Update from template" \
    --body "Update from template ${build_datetime_local}"
fi
