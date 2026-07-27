#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s TAG\n' "${0##*/}" >&2
  exit 2
fi

canonical_branch="automation/template-$1"
existing=$(
  gh pr list --state open --limit 100 --json headRefName |
    python3 -c 'import json, sys; prefix = sys.argv[1]; print(sum(item["headRefName"] == prefix or item["headRefName"].startswith(prefix + "-run-") for item in json.load(sys.stdin)))' "$canonical_branch"
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
