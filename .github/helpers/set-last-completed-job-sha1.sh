#!/bin/bash
set -exo pipefail

### find previous sucessfull tag
# shellcheck disable=SC2154
if [[ ${branch} == "master" ]]; then
    prev_build=$(git describe --tags --abbrev=0 --first-parent --exclude='????.??.??-*-*')
else
    prev_build=$(git describe --tags --abbrev=0 --first-parent)
fi
# if we have multiple tags on same commit, pick latest
prev_build=$(git tag --points-at "${prev_build}" | sort | tail -n 1)
git_prev_build_sha=$(git rev-list -n1 "${prev_build}")

function get_diff_count() {
  changed=$(git diff "${1}" --shortstat -- | awk '{print $1}')
  if [[ -z $changed ]]; then
    changed=0
  fi
  echo -n $changed
}
LAST_COMPLETED_JOB_SHA1=${git_prev_build_sha}


# this needed as we have tag only healthy builds. And probably don't want to compare with unhealthy build
master_tag=$(git describe --tags --abbrev=0 --first-parent --exclude='????.??.??-*-*' origin/master)
master_sha=$(git rev-list -n1 "${master_tag}")
changes_master=$(get_diff_count "${master_sha}")

changes_git_tag=$(get_diff_count "${git_prev_build_sha}")

changes_current_candidate=$(get_diff_count "${LAST_COMPLETED_JOB_SHA1}")

if [[ ${changes_current_candidate} -gt ${changes_master} ]]; then
  echo "as previuos will choose version from master ${master_tag}"
  LAST_COMPLETED_JOB_SHA1=${master_sha}
  changes_current_candidate=$(get_diff_count "${LAST_COMPLETED_JOB_SHA1}")
elif [[ ${changes_current_candidate} -gt ${changes_git_tag} ]]; then
  echo "as previuos will choose version from git tag ${prev_build}"
  LAST_COMPLETED_JOB_SHA1=${git_prev_build_sha}
  changes_current_candidate=$(get_diff_count "${LAST_COMPLETED_JOB_SHA1}")
fi
echo "LAST_COMPLETED_JOB_SHA1=${LAST_COMPLETED_JOB_SHA1}" >> $GITHUB_ENV


LATEST_CACHE_SHA1=${LAST_COMPLETED_JOB_SHA1}


set +xo pipefail
retrive_tag_num=30
last_builds=$(git tag -l --sort='-authordate' | head -n "${retrive_tag_num}" | uniq)
set -o pipefail
last_builds_array=($last_builds)
tmp_dir='/tmp/'
# changes_current_candidate
(get_diff_count "${LATEST_CACHE_SHA1}"; echo -n " ${LATEST_CACHE_SHA1}") > "$tmp_dir/current.diff" &
# git tags
for i in $(seq 0 "$((retrive_tag_num-1))"); do
  (get_diff_count "${last_builds_array[$i]}"; echo " ${last_builds_array[$i]}") > "$tmp_dir/$i.diff" &
done
wait
cache_candidate=$(cat "$tmp_dir"/*.diff | sort -n | head -n 1)
tag_with_min_changes=$(echo "$cache_candidate" | awk '{print $2}')
min_changes=$(echo "$cache_candidate" | awk '{print $1}')

echo "as previous will choose version from commit  ${tag_with_min_changes} with ${min_changes} changes"
LATEST_CACHE_SHA1=$(git rev-list -n1 "${tag_with_min_changes}")
changes_current_candidate=$(get_diff_count "${LATEST_CACHE_SHA1}")

echo "LATEST_CACHE_SHA1=${LATEST_CACHE_SHA1}" >> $GITHUB_ENV
