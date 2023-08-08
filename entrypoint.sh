#!/bin/sh -l

src_dir=${GITHUB_WORKSPACE:-/github/workspace}/${SOURCE_DIR}
dest_dir=${GITHUB_WORKSPACE:-/github/workspace}/${DESTINATION_DIR}

# ==============================================================================

cd ${dest_dir}
git config user.name "${GIT_USER_NAME}"
git config user.email "${GIT_USER_EMAIL}@users.noreply.github.com"
git config --global --add safe.directory ${dest_dir}
# Close PRs
pr_numbers=$(gh pr list --search "Update from template" --json number,title | jq '.[] | select(.title | startswith("Update from template")).number')
for pr_number in $pr_numbers; do
  gh pr close $pr_number
done
# Delete branches
for branch in $(git branch -r | grep 'origin/update-from-template'); do
  git push origin --delete ${branch#origin/}
done
git checkout -b update-from-template-${BUILD_DATETIME}

# ==============================================================================

/compare-directories \
  --source-dir ${src_dir} \
  --destination-dir ${dest_dir} \
  --app-config-file /.config.yaml \
  --template-config-file ${dest_dir}/scripts/config/.repository-template.yaml \
> /tmp/compare-directories.json

to_update=$(
  cat /tmp/compare-directories.json \
    | jq -r '.comparison | to_entries[] | select(.value.action == "update") | .key'
)
echo "$to_update" | while IFS= read -r file; do
  dir=$(dirname "$file")
  mkdir -p ${dest_dir}/$dir
  cp ${src_dir}/$file ${dest_dir}/$file
done

to_delete=$(
  cat /tmp/compare-directories.json \
    | jq -r '.comparison | to_entries[] | select(.value.action == "delete") | .key'
)
echo "$to_delete" | while IFS= read -r file; do
  rm -rf ${dest_dir}/$file
done

# ==============================================================================

git add -A
git commit -m "Update from template $(date --date=${BUILD_DATETIME} +'%Y-%m-%dT%H:%M:%S%z')"
git push -u origin update-from-template-$(date --date=${BUILD_DATETIME} -u +'%Y%m%d%H%M%S')
gh pr create \
  --title "Update from template" \
  --body "Update from template $(date --date=${BUILD_DATETIME} +'%Y-%m-%dT%H:%M:%S%z')"
