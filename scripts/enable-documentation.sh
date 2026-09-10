#!/bin/bash
set -euo pipefail

repository='margelo/VisionCamera'

if [[ "$(gh api "repos/$repository" --jq '.private')" != 'false' ]]; then
  echo 'Make margelo/VisionCamera public before enabling its documentation website.' >&2
  exit 1
fi

# Use the administrator's local GitHub CLI session for this one-time setting.
# GITHUB_TOKEN can deploy to an existing Pages site, but cannot create one.
if gh api "repos/$repository/pages" >/dev/null 2>&1; then
  gh api --method PUT "repos/$repository/pages" -f build_type=workflow >/dev/null
else
  gh api --method POST "repos/$repository/pages" -f build_type=workflow >/dev/null
fi

gh workflow run documentation.yml --repo "$repository" --ref main -f deploy=true

echo 'Documentation publishing started.'
echo 'Progress: https://github.com/margelo/VisionCamera/actions/workflows/documentation.yml'
echo 'Website: https://margelo.github.io/VisionCamera/'
