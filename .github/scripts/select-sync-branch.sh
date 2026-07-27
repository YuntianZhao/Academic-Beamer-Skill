#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s TAG\n' "${0##*/}" >&2
  exit 2
fi

canonical_branch="automation/template-$1"
repository_owner=${GITHUB_REPOSITORY%%/*}
existing=$(
  gh pr list --repo "$GITHUB_REPOSITORY" --state open --limit 100 \
    --json headRefName,headRepositoryOwner,isCrossRepository |
    python3 -c 'import json, sys; prefix, expected_owner = sys.argv[1:]; print(sum((item["headRefName"] == prefix or item["headRefName"].startswith(prefix + "-run-")) and item["isCrossRepository"] is False and (item["headRepositoryOwner"] or {}).get("login", "").casefold() == expected_owner.casefold() for item in json.load(sys.stdin)))' "$canonical_branch" "$repository_owner"
)
if [ "$existing" -gt 0 ]; then
  exit 0
fi

remote_count=$(gh api "repos/$GITHUB_REPOSITORY/git/matching-refs/heads/$canonical_branch" --jq 'length')
if [ "$remote_count" -gt 0 ]; then
  printf '%s-run-%s-%s\n' "$canonical_branch" "$GITHUB_RUN_ID" "$GITHUB_RUN_ATTEMPT"
else
  printf '%s\n' "$canonical_branch"
fi
