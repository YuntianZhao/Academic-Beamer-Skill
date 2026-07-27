#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SCRIPT="$ROOT_DIR/.github/scripts/select-sync-branch.sh"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/academic-beamer-sync-branch.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
[ -x "$SCRIPT" ] || fail 'select-sync-branch.sh is missing or not executable'

mkdir "$TMP_DIR/bin"
cat > "$TMP_DIR/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$GH_LOG"

if [ "$1 $2" = 'pr list' ]; then
  case "$GH_SCENARIO" in
    open-canonical)
      printf '[{"headRefName":"automation/template-v2.0.0","headRepositoryOwner":{"login":"example"},"isCrossRepository":false}]\n'
      ;;
    open-retry)
      printf '[{"headRefName":"automation/template-v2.0.0-run-10-1","headRepositoryOwner":{"login":"example"},"isCrossRepository":false}]\n'
      ;;
    external-canonical)
      printf '[{"headRefName":"automation/template-v2.0.0","headRepositoryOwner":{"login":"external"},"isCrossRepository":true}]\n'
      ;;
    unrelated-open)
      printf '[{"headRefName":"feature/unrelated","headRepositoryOwner":{"login":"example"},"isCrossRepository":false}]\n'
      ;;
    *)
      printf '[]\n'
      ;;
  esac
elif [ "$1" = 'api' ]; then
  [ "$2" = 'repos/example/project/git/matching-refs/heads/automation/template-v2.0.0' ] || {
    printf 'unexpected API endpoint: %s\n' "$2" >&2
    exit 2
  }
  case "$GH_SCENARIO" in
    canonical-exists|retry-exists) printf '1\n' ;;
    *) printf '0\n' ;;
  esac
else
  printf 'unexpected gh command: %s\n' "$*" >&2
  exit 2
fi
EOF
chmod +x "$TMP_DIR/bin/gh"

run_scenario() {
  GH_SCENARIO=$1 \
    GH_LOG="$TMP_DIR/$1.log" \
    GITHUB_REPOSITORY=example/project \
    GITHUB_RUN_ID=42 \
    GITHUB_RUN_ATTEMPT=3 \
    PATH="$TMP_DIR/bin:$PATH" \
    "$SCRIPT" v2.0.0
}

[ "$(run_scenario no-remote)" = 'automation/template-v2.0.0' ] || fail 'missing remote branch should select canonical branch'
[ "$(run_scenario unrelated-open)" = 'automation/template-v2.0.0' ] || fail 'unrelated open PR should not suppress synchronization'
[ "$(run_scenario external-canonical)" = 'automation/template-v2.0.0' ] || fail 'external fork with canonical branch should not suppress synchronization'
[ "$(run_scenario canonical-exists)" = 'automation/template-v2.0.0-run-42-3' ] || fail 'existing canonical branch should select retry branch'
[ "$(run_scenario retry-exists)" = 'automation/template-v2.0.0-run-42-3' ] || fail 'existing retry branch should select a new run-specific branch'
[ -z "$(run_scenario open-canonical)" ] || fail 'open canonical PR should be a no-op'
[ -z "$(run_scenario open-retry)" ] || fail 'open retry PR should be a no-op'

if rg --fixed-strings --quiet 'api ' "$TMP_DIR/open-canonical.log"; then
  fail 'open canonical PR should not query remote branch refs'
fi
if rg --fixed-strings --quiet 'api ' "$TMP_DIR/open-retry.log"; then
  fail 'open retry PR should not query remote branch refs'
fi
rg --fixed-strings --quiet \
  'pr list --repo example/project --state open --limit 100 --json headRefName,headRepositoryOwner,isCrossRepository' \
  "$TMP_DIR/external-canonical.log" || fail 'PR lookup does not request repository trust metadata'

printf 'Synchronization branch selection tests passed.\n'
