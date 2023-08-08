#!/bin/sh -l

src_dir=${GITHUB_WORKSPACE:-/github/workspace}/${SOURCE_DIR}
dest_dir=${GITHUB_WORKSPACE:-/github/workspace}/${DESTINATION_DIR}

# ==============================================================================

# Global git settings
git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}@users.noreply.github.com"
git config --global pull.rebase false
git config --global --add safe.directory ${dest_dir/\/.\//\/}

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
# Create new branch
git checkout -b update-from-template-${BUILD_TIMESTAMP}

# ==============================================================================

# Produce a list of files to update and delete
/compare-directories \
  --source-dir ${src_dir} \
  --destination-dir ${dest_dir} \
  --app-config-file /.config.yaml \
  --template-config-file ${dest_dir}/scripts/config/.repository-template.yaml \
> /tmp/compare-directories.json
# Update files
to_update=$(
  cat /tmp/compare-directories.json \
    | jq -r '.comparison | to_entries[] | select(.value.action == "update") | .key'
)
echo "$to_update" | while IFS= read -r file; do
  dir=$(dirname "$file")
  mkdir -p ${dest_dir}/$dir
  cp ${src_dir}/$file ${dest_dir}/$file
done
# Delete files
to_delete=$(
  cat /tmp/compare-directories.json \
    | jq -r '.comparison | to_entries[] | select(.value.action == "delete") | .key'
)
echo "$to_delete" | while IFS= read -r file; do
  rm -rf ${dest_dir}/$file
done

# ==============================================================================

# Commit and push changes
git add -A
git commit -m "Update from template ${BUILD_DATETIME_LOCAL}"
git push -u origin update-from-template-${BUILD_TIMESTAMP}
# Create new PR
gh pr create \
  --title "Update from template" \
  --body "Update from template ${BUILD_DATETIME_LOCAL}"
